<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Supplement extends Model
{
    protected $fillable = [
        'user_id', 'name', 'kind', 'dose', 'form',
        'stock_units', 'frequency', 'times',
        'with_food', 'reminder_on', 'track_stock', 'note',
    ];

    protected function casts(): array
    {
        return [
            'times'       => 'array',
            'with_food'   => 'boolean',
            'reminder_on' => 'boolean',
            'track_stock' => 'boolean',
        ];
    }

    public function user(): BelongsTo     { return $this->belongsTo(User::class); }
    public function intakes(): HasMany    { return $this->hasMany(SupplementIntake::class); }
}
