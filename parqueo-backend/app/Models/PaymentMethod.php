<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class PaymentMethod extends Model
{
    use HasFactory;

    protected $fillable = [
        'parking_id',
        'name',
        'code',
        'icon',
        'instructions',
        'qr_image_path',
        'bank_name',
        'account_holder',
        'account_number',
        'phone_number',
        'requires_reference',
        'is_active',
        'order',
    ];

    protected $casts = [
        'requires_reference' => 'boolean',
        'is_active' => 'boolean',
        'order' => 'integer',
    ];

    protected $appends = [
        'qr_image_url',
    ];

    public function getQrImageUrlAttribute(): ?string
    {
        if ($this->qr_image_path) {
            return url(Storage::url($this->qr_image_path));
        }
        return null;
    }

    public function parking(): BelongsTo
    {
        return $this->belongsTo(Parking::class);
    }
}
