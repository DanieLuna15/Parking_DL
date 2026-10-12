<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class VehicleType extends Model
{
    use HasFactory;

    protected $fillable = [
        'parking_id',
        'name',
        'icon',
        'rate_per_hour',
        'rate_per_fraction',
        'fraction_minutes',
        'grace_period_minutes',
        'flat_day_rate',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'rate_per_hour' => 'decimal:2',
            'rate_per_fraction' => 'decimal:2',
            'flat_day_rate' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function parking(): BelongsTo
    {
        return $this->belongsTo(Parking::class);
    }

    public function entries(): HasMany
    {
        return $this->hasMany(VehicleEntry::class);
    }

    /**
     * Calcula la tarifa según la duración en minutos.
     */
    public function calculateFee(int $durationMinutes): float
    {
        // 1. Si está dentro del período de gracia, es gratis
        if ($durationMinutes <= $this->grace_period_minutes) {
            return 0.00;
        }

        // Si existe tarifa plana por día y supera 12 horas (720 min)
        if ($this->flat_day_rate && $durationMinutes >= 720 && $durationMinutes <= 1440) {
            return (float) $this->flat_day_rate;
        }

        // 2. Cálculo estándar por horas y fracciones
        $hours = intdiv($durationMinutes, 60);
        $remainingMinutes = $durationMinutes % 60;

        $total = $hours * (float) $this->rate_per_hour;

        if ($remainingMinutes > 0) {
            if ($this->fraction_minutes > 0 && $this->rate_per_fraction > 0) {
                $fractions = (int) ceil($remainingMinutes / $this->fraction_minutes);
                $total += $fractions * (float) $this->rate_per_fraction;
            } else {
                // Si no hay fracción configurada, se cobra la hora completa siguiente
                $total += (float) $this->rate_per_hour;
            }
        }

        // El cobro mínimo al salir si supera el tiempo de gracia es al menos 1 fracción o 1 hora
        if ($total <= 0) {
            $total = (float) ($this->rate_per_fraction > 0 ? $this->rate_per_fraction : $this->rate_per_hour);
        }

        return round($total, 2);
    }
}
