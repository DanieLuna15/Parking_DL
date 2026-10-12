<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VehicleExit extends Model
{
    use HasFactory;

    protected $fillable = [
        'vehicle_entry_id',
        'parking_id',
        'user_id',
        'exit_time',
        'duration_minutes',
        'calculated_amount',
        'discount_amount',
        'total_paid',
        'payment_method',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'exit_time' => 'datetime',
            'calculated_amount' => 'decimal:2',
            'discount_amount' => 'decimal:2',
            'total_paid' => 'decimal:2',
        ];
    }

    public function entry(): BelongsTo
    {
        return $this->belongsTo(VehicleEntry::class, 'vehicle_entry_id');
    }

    public function parking(): BelongsTo
    {
        return $this->belongsTo(Parking::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
