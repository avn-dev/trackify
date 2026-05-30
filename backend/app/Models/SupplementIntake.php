<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SupplementIntake extends Model
{
    protected $fillable = ['supplement_id', 'user_id', 'planned_at', 'taken_at', 'skipped'];

    protected function casts(): array
    {
        return [
            'planned_at' => 'datetime',
            'taken_at'   => 'datetime',
            'skipped'    => 'boolean',
        ];
    }

    public function supplement(): BelongsTo { return $this->belongsTo(Supplement::class); }
    public function user(): BelongsTo       { return $this->belongsTo(User::class); }
}
