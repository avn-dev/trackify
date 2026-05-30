<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LabValue extends Model
{
    protected $fillable = ['lab_measurement_id', 'marker', 'value', 'unit', 'ref_low', 'ref_high', 'category'];

    protected function casts(): array
    {
        return ['value' => 'float', 'ref_low' => 'float', 'ref_high' => 'float'];
    }

    public function measurement(): BelongsTo { return $this->belongsTo(LabMeasurement::class); }
}
