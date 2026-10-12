<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehicleEntry;
use App\Models\VehicleExit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ExitController extends Controller
{
    /**
     * Cotizar / Calcular tarifa antes de completar la salida (Vehicle Exit Preview).
     */
    public function calculate(Request $request): JsonResponse
    {
        $request->validate([
            'query' => 'required|string', // Puede ser la placa o el ticket_code
        ]);

        $user = $request->user();
        $parkingId = $user->parking_id ?? 1;
        $search = strtoupper(trim($request->query('query', $request->input('query'))));

        $entry = VehicleEntry::where('parking_id', $parkingId)
            ->where('status', 'inside')
            ->where(function ($q) use ($search) {
                $q->where('license_plate', $search)
                  ->orWhere('ticket_code', $search);
            })
            ->with(['vehicleType', 'parking', 'user'])
            ->first();

        if (!$entry) {
            return response()->json([
                'success' => false,
                'message' => "No se encontró ningún vehículo activo adentro con la placa o ticket: '{$search}'.",
            ], 404);
        }

        $now = now();
        $durationMinutes = (int) $entry->entry_time->diffInMinutes($now);
        $hours = intdiv($durationMinutes, 60);
        $mins = $durationMinutes % 60;

        $calculatedFee = $entry->vehicleType->calculateFee($durationMinutes);

        return response()->json([
            'success' => true,
            'data' => [
                'entry_id' => $entry->id,
                'ticket_code' => $entry->ticket_code,
                'license_plate' => $entry->license_plate,
                'vehicle_type' => [
                    'id' => $entry->vehicleType->id,
                    'name' => $entry->vehicleType->name,
                    'icon' => $entry->vehicleType->icon,
                    'rate_per_hour' => $entry->vehicleType->rate_per_hour,
                    'rate_per_fraction' => $entry->vehicleType->rate_per_fraction,
                    'grace_period_minutes' => $entry->vehicleType->grace_period_minutes,
                ],
                'entry_time' => $entry->entry_time->format('Y-m-d H:i:s'),
                'exit_time' => $now->format('Y-m-d H:i:s'),
                'duration_minutes' => $durationMinutes,
                'duration_formatted' => "{$hours} Horas {$mins} Minutos",
                'parking_fee' => $calculatedFee,
                'currency' => $entry->parking->currency_symbol,
            ],
        ]);
    }

    /**
     * Procesar cobro y completar la salida del vehículo (Complete Exit).
     */
    public function complete(Request $request): JsonResponse
    {
        $request->validate([
            'entry_id' => 'required|exists:vehicle_entries,id',
            'payment_method' => 'required|in:cash,e_wallet,card',
            'discount_amount' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string|max:500',
        ]);

        $user = $request->user();
        $parkingId = $user->parking_id ?? 1;

        $entry = VehicleEntry::where('id', $request->entry_id)
            ->where('parking_id', $parkingId)
            ->with(['vehicleType', 'parking'])
            ->firstOrFail();

        if ($entry->status !== 'inside') {
            return response()->json([
                'success' => false,
                'message' => 'Este vehículo ya ha completado su salida previamente.',
            ], 422);
        }

        $now = now();
        $durationMinutes = (int) $entry->entry_time->diffInMinutes($now);
        $calculatedFee = $entry->vehicleType->calculateFee($durationMinutes);
        $discount = (float) ($request->discount_amount ?? 0.00);
        $totalPaid = max(0, $calculatedFee - $discount);

        // Crear registro de salida
        $exit = VehicleExit::create([
            'vehicle_entry_id' => $entry->id,
            'parking_id' => $parkingId,
            'user_id' => $user->id,
            'exit_time' => $now,
            'duration_minutes' => $durationMinutes,
            'calculated_amount' => $calculatedFee,
            'discount_amount' => $discount,
            'total_paid' => $totalPaid,
            'payment_method' => $request->payment_method,
            'notes' => $request->notes,
        ]);

        // Actualizar estado del ingreso
        $entry->update(['status' => 'exited']);

        $hours = intdiv($durationMinutes, 60);
        $mins = $durationMinutes % 60;

        return response()->json([
            'success' => true,
            'message' => 'Salida y cobro procesados correctamente.',
            'data' => [
                'exit_id' => $exit->id,
                'ticket_code' => $entry->ticket_code,
                'license_plate' => $entry->license_plate,
                'vehicle_type' => $entry->vehicleType->name,
                'entry_time' => $entry->entry_time->format('Y-m-d H:i:s'),
                'exit_time' => $exit->exit_time->format('Y-m-d H:i:s'),
                'duration_formatted' => "{$hours} Horas {$mins} Minutos",
                'calculated_amount' => $exit->calculated_amount,
                'discount' => $exit->discount_amount,
                'total_paid' => $exit->total_paid,
                'payment_method' => $exit->payment_method,
                'currency' => $entry->parking->currency_symbol,
                'cashier' => $user->name,
                'receipt_header' => $entry->parking->receipt_header,
                'receipt_footer' => $entry->parking->receipt_footer,
            ],
        ]);
    }
}
