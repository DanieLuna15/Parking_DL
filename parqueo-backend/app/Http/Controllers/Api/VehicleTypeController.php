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

        $query = VehicleType::where('parking_id', $parkingId);

        if (!$request->boolean('all')) {
            $query->where('is_active', true);
        }

        $types = $query->orderBy('id', 'asc')->get();

        return response()->json([
            'success' => true,
            'data' => $types,
        ]);
    }

    /**
     * Crear nuevo tipo de vehículo y tarifa.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'icon' => 'nullable|string|max:50',
            'rate_per_hour' => 'required|numeric|min:0',
            'rate_per_fraction' => 'nullable|numeric|min:0',
            'fraction_minutes' => 'nullable|integer|min:1',
            'grace_period_minutes' => 'nullable|integer|min:0',
            'flat_day_rate' => 'nullable|numeric|min:0',
        ]);

        $parkingId = $request->user()->parking_id ?? 1;

        $type = VehicleType::create([
            'parking_id' => $parkingId,
            'name' => $request->name,
            'icon' => $request->icon ?? 'car',
            'rate_per_hour' => $request->rate_per_hour,
            'rate_per_fraction' => $request->rate_per_fraction ?? 0,
            'fraction_minutes' => $request->fraction_minutes ?? 15,
            'grace_period_minutes' => $request->grace_period_minutes ?? 15,
            'flat_day_rate' => $request->flat_day_rate,
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Tipo de vehículo y tarifas creados correctamente.',
            'data' => $type,
        ]);
    }

    /**
     * Actualizar configuración de tarifas (Tariff Settings).
     */
    public function update(Request $request, VehicleType $vehicleType): JsonResponse
    {
        $request->validate([
            'name' => 'nullable|string|max:100',
            'icon' => 'nullable|string|max:50',
            'rate_per_hour' => 'required|numeric|min:0',
            'rate_per_fraction' => 'nullable|numeric|min:0',
            'fraction_minutes' => 'nullable|integer|min:1',
            'grace_period_minutes' => 'nullable|integer|min:0',
            'flat_day_rate' => 'nullable|numeric|min:0',
            'is_active' => 'nullable|boolean',
        ]);

        $vehicleType->update($request->only([
            'name',
            'icon',
            'rate_per_hour',
            'rate_per_fraction',
            'fraction_minutes',
            'grace_period_minutes',
            'flat_day_rate',
            'is_active',
        ]));

        return response()->json([
            'success' => true,
            'message' => 'Tarifas actualizadas correctamente.',
            'data' => $vehicleType,
        ]);
    }

    /**
     * Eliminar tipo de vehículo.
     */
    public function destroy(VehicleType $vehicleType): JsonResponse
    {
        $vehicleType->delete();

        return response()->json([
            'success' => true,
            'message' => 'Tipo de vehículo eliminado correctamente.',
        ]);
    }
}
