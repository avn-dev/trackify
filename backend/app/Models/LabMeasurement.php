<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class LabMeasurement extends Model
{
    protected $fillable = ['user_id', 'taken_at', 'source', 'raw_pdf_url'];

    protected function casts(): array
    {
        return ['taken_at' => 'datetime'];
    }

    public function user(): BelongsTo   { return $this->belongsTo(User::class); }
    public function values(): HasMany   { return $this->hasMany(LabValue::class); }
}
