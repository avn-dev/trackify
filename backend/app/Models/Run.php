<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Run extends Model
{
    protected $fillable = [
        'user_id', 'started_at', 'ended_at',
        'distance_m', 'duration_s', 'gain_m',
        'polyline', 'splits_json',
    ];

    protected function casts(): array
    {
        return [
            'started_at'  => 'datetime',
            'ended_at'    => 'datetime',
            'distance_m'  => 'float',
            'gain_m'      => 'float',
        ];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
