<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'apple_id',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
        ];
    }

    // Relations
    public function workouts()    { return $this->hasMany(Workout::class); }
    public function runs()        { return $this->hasMany(Run::class); }
    public function bodyMetrics() { return $this->hasMany(BodyMetric::class); }
    public function labMeasurements() { return $this->hasMany(LabMeasurement::class); }
    public function supplements() { return $this->hasMany(Supplement::class); }
}
