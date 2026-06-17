<?php

namespace Tests\Feature;

use App\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/**
 * Verifies that POST /auth/apple cryptographically validates the Apple identity token
 * rather than trusting an unsigned, base64-decoded JWT (which was a full auth bypass).
 */
class AppleAuthTest extends TestCase
{
    use RefreshDatabase;

    private const KID = 'test-key';

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.apple.client_id' => 'app.trackify.ios']);
    }

    /** Generates an RSA keypair and returns [privatePem, jwksArray]. */
    private function makeKeypair(string $kid = self::KID): array
    {
        $res = openssl_pkey_new([
            'private_key_bits' => 2048,
            'private_key_type' => OPENSSL_KEYTYPE_RSA,
        ]);
        openssl_pkey_export($res, $privatePem);
        $details = openssl_pkey_get_details($res);

        $b64url = fn (string $bin) => rtrim(strtr(base64_encode($bin), '+/', '-_'), '=');
        $jwk = [
            'kty' => 'RSA',
            'kid' => $kid,
            'use' => 'sig',
            'alg' => 'RS256',
            'n'   => $b64url($details['rsa']['n']),
            'e'   => $b64url($details['rsa']['e']),
        ];

        return [$privatePem, ['keys' => [$jwk]]];
    }

    private function claims(array $overrides = []): array
    {
        return array_merge([
            'iss'   => 'https://appleid.apple.com',
            'aud'   => 'app.trackify.ios',
            'sub'   => 'apple-sub-123',
            'email' => 'apple@example.com',
            'iat'   => time(),
            'exp'   => time() + 3600,
            'nonce' => hash('sha256', 'raw-nonce'),
        ], $overrides);
    }

    public function test_valid_apple_token_authenticates_and_creates_user(): void
    {
        [$privatePem, $jwks] = $this->makeKeypair();
        Http::fake(['appleid.apple.com/*' => Http::response($jwks)]);

        $token = JWT::encode($this->claims(), $privatePem, 'RS256', self::KID);

        $response = $this->postJson('/auth/apple', [
            'identity_token' => $token,
            'nonce'          => 'raw-nonce',
        ]);

        $response->assertOk()->assertJsonStructure(['token', 'user' => ['id', 'name', 'email']]);
        $this->assertDatabaseHas('users', ['apple_id' => 'apple-sub-123', 'email' => 'apple@example.com']);
    }

    public function test_token_signed_with_unknown_key_is_rejected(): void
    {
        // Apple publishes keypair A, but the attacker signs the token with their own keypair B.
        [, $applesJwks] = $this->makeKeypair();
        [$attackerPem] = $this->makeKeypair();
        Http::fake(['appleid.apple.com/*' => Http::response($applesJwks)]);

        $forged = JWT::encode($this->claims(['sub' => 'attacker', 'email' => 'attacker@evil.test']), $attackerPem, 'RS256', self::KID);

        $response = $this->postJson('/auth/apple', [
            'identity_token' => $forged,
            'nonce'          => 'raw-nonce',
        ]);

        $response->assertStatus(422);
        $this->assertDatabaseMissing('users', ['apple_id' => 'attacker']);
        $this->assertSame(0, User::count());
    }

    public function test_token_with_wrong_audience_is_rejected(): void
    {
        [$privatePem, $jwks] = $this->makeKeypair();
        Http::fake(['appleid.apple.com/*' => Http::response($jwks)]);

        $token = JWT::encode($this->claims(['aud' => 'com.someone.else']), $privatePem, 'RS256', self::KID);

        $response = $this->postJson('/auth/apple', [
            'identity_token' => $token,
            'nonce'          => 'raw-nonce',
        ]);

        $response->assertStatus(422);
        $this->assertSame(0, User::count());
    }

    public function test_unsigned_garbage_token_is_rejected(): void
    {
        [, $jwks] = $this->makeKeypair();
        Http::fake(['appleid.apple.com/*' => Http::response($jwks)]);

        $response = $this->postJson('/auth/apple', [
            'identity_token' => 'not.a.jwt',
            'nonce'          => 'raw-nonce',
        ]);

        $response->assertStatus(422);
        $this->assertSame(0, User::count());
    }
}
