<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Workout extends Model
{
    protected $fillable = ['user_id', 'plan_day', 'started_at', 'ended_at', 'volume_kg'];

    protected function casts(): array
    {
        return ['started_at' => 'datetime', 'ended_at' => 'datetime', 'volume_kg' => 'float'];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function sets(): HasMany   { return $this->hasMany(WorkoutSet::class); }
}
