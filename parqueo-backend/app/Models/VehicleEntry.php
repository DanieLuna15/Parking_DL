<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class VehicleEntry extends Model
{
    use HasFactory;

    protected $fillable = [
        'parking_id',
        'vehicle_type_id',
        'user_id',
        'ticket_code',
        'license_plate',
        'entry_time',
        'photo_path',
        'notes',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'entry_time' => 'datetime',
        ];
    }

    public function parking(): BelongsTo
    {
        return $this->belongsTo(Parking::class);
    }

    public function vehicleType(): BelongsTo
    {
        return $this->belongsTo(VehicleType::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function exit(): HasOne
    {
        return $this->hasOne(VehicleExit::class);
    }

    /**
     * Generador de código de ticket único.
     */
    public static function generateTicketCode(int $parkingId): string
    {
        $today = now()->format('Ymd');
        $count = self::where('parking_id', $parkingId)
            ->whereDate('entry_time', now()->toDateString())
            ->count() + 1;

        return sprintf('TKT-%s-%04d', $today, $count);
    }
}
