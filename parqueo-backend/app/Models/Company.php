<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Company extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'document_number',
        'phone',
        'address',
        'logo_url',
        'status',
        'subscription_plan',
        'subscription_expires_at',
    ];

    protected function casts(): array
    {
        return [
            'subscription_expires_at' => 'datetime',
        ];
    }

    public function parkings(): HasMany
    {
        return $this->hasMany(Parking::class);
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }
}
