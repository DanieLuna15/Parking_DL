<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehicleEntry;
use App\Models\VehicleExit;
use App\Models\VehicleType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Resumen en vivo para el Dashboard (exacto como en el Mockup de la imagen).
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $parkingId = $user->parking_id ?? 1;

        // 1. Vehículos adentro por tipo
        $insideEntries = VehicleEntry::where('parking_id', $parkingId)
            ->where('status', 'inside')
            ->with('vehicleType')
            ->get();

        $totalInside = $insideEntries->count();

        // Desglose por tipos
        $types = VehicleType::where('parking_id', $parkingId)
            ->where('is_active', true)
            ->get();

        $breakdown = $types->map(function ($type) use ($insideEntries) {
            $count = $insideEntries->where('vehicle_type_id', $type->id)->count();
            return [
                'id' => $type->id,
                'name' => $type->name,
                'icon' => $type->icon,
                'count' => $count,
                'rate_per_hour' => $type->rate_per_hour,
            ];
        });

        // 2. Capacidad del parqueo
        $parking = $user->parking ?? \App\Models\Parking::find($parkingId);
        $totalCapacity = $parking ? $parking->total_capacity : 50;
        $availableSpots = max(0, $totalCapacity - $totalInside);

        // 3. Métricas de hoy
        $todayExits = VehicleExit::where('parking_id', $parkingId)
            ->whereDate('exit_time', now()->toDateString())
            ->get();

        $todayRevenue = $todayExits->sum('total_paid');
        $todayTransactions = $todayExits->count();

        return response()->json([
            'success' => true,
            'data' => [
                'parking_name' => $parking ? $parking->name : 'ParkinGo',
                'currency' => $parking ? $parking->currency_symbol : '$',
                'vehicles_inside' => $totalInside,
                'total_capacity' => $totalCapacity,
                'available_spots' => $availableSpots,
                'occupancy_percentage' => $totalCapacity > 0 ? round(($totalInside / $totalCapacity) * 100, 1) : 0,
                'breakdown' => $breakdown,
                'today_revenue' => (float) $todayRevenue,
                'today_transactions' => $todayTransactions,
            ],
        ]);
    }
}
