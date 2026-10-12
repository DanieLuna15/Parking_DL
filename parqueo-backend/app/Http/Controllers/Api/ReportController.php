<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehicleEntry;
use App\Models\VehicleExit;
use App\Models\VehicleType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ReportController extends Controller
{
    /**
     * Reporte general diario / por fecha (Mockup pantalla Reports).
     */
    public function daily(Request $request): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;
        $dateStr = $request->query('date', now()->toDateString());
        $date = Carbon::parse($dateStr);

        // 1. Salidas cobradas en la fecha
        $exits = VehicleExit::where('parking_id', $parkingId)
            ->whereDate('exit_time', $date)
            ->with('entry.vehicleType')
            ->get();

        // 2. Entradas registradas en la fecha
        $entries = VehicleEntry::where('parking_id', $parkingId)
            ->whereDate('entry_time', $date)
            ->with('vehicleType')
            ->get();

        $totalRevenue = $exits->sum('total_paid');
        $totalVehicles = $entries->count();

        // 3. Desglose por tipo de vehículo
        $vehicleTypes = VehicleType::where('parking_id', $parkingId)->get();
        $typeBreakdown = $vehicleTypes->map(function ($type) use ($entries, $totalVehicles) {
            $count = $entries->where('vehicle_type_id', $type->id)->count();
            $pct = $totalVehicles > 0 ? round(($count / $totalVehicles) * 100) : 0;
            return [
                'id' => $type->id,
                'name' => $type->name,
                'icon' => $type->icon,
                'count' => $count,
                'percentage' => $pct,
            ];
        });

        // 4. Gráfico de ingresos por horas (08:00, 10:00, 12:00, 14:00, 16:00, etc.)
        $hours = [8, 10, 12, 14, 16, 18, 20];
        $chartData = [];

        foreach ($hours as $h) {
            $hourStart = $date->copy()->setHour($h)->setMinute(0)->setSecond(0);
            $hourEnd = $hourStart->copy()->addHours(2);

            $revenueInSlot = $exits->filter(function ($exit) use ($hourStart, $hourEnd) {
                return $exit->exit_time >= $hourStart && $exit->exit_time < $hourEnd;
            })->sum('total_paid');

            $chartData[] = [
                'hour' => sprintf('%02d:00', $h),
                'revenue' => (float) $revenueInSlot,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => [
                'date' => $date->toDateString(),
                'total_vehicles' => $totalVehicles,
                'total_revenue' => (float) $totalRevenue,
                'type_breakdown' => $typeBreakdown,
                'chart_data' => $chartData,
            ],
        ]);
    }
}
