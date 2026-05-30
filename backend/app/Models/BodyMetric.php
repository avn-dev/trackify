<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BodyMetric extends Model
{
    protected $fillable = ['user_id', 'ts', 'type', 'value', 'method'];

    protected function casts(): array
    {
        return ['ts' => 'datetime', 'value' => 'float'];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
}
