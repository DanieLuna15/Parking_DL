<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehicleType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VehicleTypeController extends Controller
{
    /**
     * Listar tipos de vehículo con tarifas del parqueo actual.
     */
    public function index(Request $request): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;

        $types = VehicleType::where('parking_id', $parkingId)
            ->where('is_active', true)
            ->orderBy('id', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $types,
        ]);
    }

    /**
     * Actualizar configuración de tarifas (Tariff Settings).
     */
    public function update(Request $request, VehicleType $vehicleType): JsonResponse
    {
        $request->validate([
            'rate_per_hour' => 'required|numeric|min:0',
            'rate_per_fraction' => 'nullable|numeric|min:0',
            'fraction_minutes' => 'nullable|integer|min:1',
            'grace_period_minutes' => 'nullable|integer|min:0',
            'flat_day_rate' => 'nullable|numeric|min:0',
        ]);

        $vehicleType->update($request->only([
            'rate_per_hour',
            'rate_per_fraction',
            'fraction_minutes',
            'grace_period_minutes',
            'flat_day_rate',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Tarifas actualizadas correctamente.',
            'data' => $vehicleType,
        ]);
    }
}
