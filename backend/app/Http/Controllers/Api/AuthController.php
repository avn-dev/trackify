<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    // POST /api/auth/login
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Die angegebenen Zugangsdaten sind falsch.'],
            ]);
        }

        $token = $user->createToken('trackify-ios')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $this->userPayload($user),
        ]);
    }

    // POST /api/auth/register
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
        ]);

        $user = User::create([
            'name'     => $data['name'],
            'email'    => $data['email'],
            'password' => Hash::make($data['password']),
        ]);

        $token = $user->createToken('trackify-ios')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $this->userPayload($user),
        ], 201);
    }

    // POST /api/auth/apple
    // The iOS app sends the Apple identity token; we verify it and issue a Sanctum token.
    public function apple(Request $request): JsonResponse
    {
        $data = $request->validate([
            'identity_token' => 'required|string',
            'nonce'          => 'required|string',
        ]);

        // Decode the JWT header/payload (no library needed for the public-key check skeleton).
        // In production: use web-token/jwt-library or lcobucci/jwt to verify the RS256 signature
        // against Apple's public keys at https://appleid.apple.com/auth/keys
        $parts   = explode('.', $data['identity_token']);
        $payload = json_decode(base64_decode(strtr($parts[1] ?? '', '-_', '+/')), true);

        if (! $payload || empty($payload['sub']) || empty($payload['email'])) {
            return response()->json(['message' => 'Ungültiger Apple Token.'], 422);
        }

        // Verify nonce hash matches what the app sent
        if (($payload['nonce'] ?? '') !== hash('sha256', $data['nonce'])) {
            return response()->json(['message' => 'Nonce stimmt nicht überein.'], 422);
        }

        $user = User::firstOrCreate(
            ['apple_id' => $payload['sub']],
            [
                'name'     => $payload['name'] ?? 'Trackify-Nutzer',
                'email'    => $payload['email'],
                'password' => Hash::make(str()->random(32)),
            ]
        );

        $token = $user->createToken('trackify-ios-apple')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user'  => $this->userPayload($user),
        ]);
    }

    // GET /api/auth/me
    public function me(Request $request): JsonResponse
    {
        return response()->json($this->userPayload($request->user()));
    }

    // POST /api/auth/logout
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(null, 204);
    }

    private function userPayload(User $user): array
    {
        return [
            'id'    => $user->id,
            'name'  => $user->name,
            'email' => $user->email,
        ];
    }
}
