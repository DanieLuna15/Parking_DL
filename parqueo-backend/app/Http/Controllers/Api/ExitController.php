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
            'payment_method' => 'required|string|max:50',
            'payment_method_id' => 'nullable|exists:payment_methods,id',
            'reference_number' => 'nullable|string|max:100',
            'discount_amount' => 'nullable|numeric|min:0',
            'penalty_amount' => 'nullable|numeric|min:0',
            'is_lost_ticket' => 'nullable|boolean',
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
        $penalty = (float) ($request->penalty_amount ?? 0.00);
        $totalPaid = max(0, $calculatedFee + $penalty - $discount);

        $notes = $request->notes;
        if ($request->boolean('is_lost_ticket') || $penalty > 0) {
            $notes = "[TICKET EXTRAVIADO (+Bs. {$penalty})] " . ($notes ?? '');
        }

        // Crear registro de salida
        $exit = VehicleExit::create([
            'vehicle_entry_id' => $entry->id,
            'parking_id' => $parkingId,
            'user_id' => $user->id,
            'exit_time' => $now,
            'duration_minutes' => $durationMinutes,
            'calculated_amount' => $calculatedFee + $penalty,
            'discount_amount' => $discount,
            'total_paid' => $totalPaid,
            'payment_method' => $request->payment_method,
            'payment_method_id' => $request->payment_method_id,
            'reference_number' => $request->reference_number,
            'notes' => $notes,
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
                'penalty_amount' => $penalty,
                'total_paid' => $exit->total_paid,
                'payment_method' => $exit->payment_method,
                'currency' => $entry->parking->currency_symbol,
                'cashier' => $user->name,
                'is_lost_ticket' => $request->boolean('is_lost_ticket') || $penalty > 0,
                'receipt_header' => $entry->parking->receipt_header,
                'receipt_footer' => $entry->parking->receipt_footer,
                'ticket_url' => url("/tickets/{$entry->ticket_code}"),
            ],
        ]);
    }

    /**
     * Cobro directo y forzado de Ticket Perdido cuando el cliente no tiene boleto ni aparece registro previo.
     */
    public function completeLostTicket(Request $request): JsonResponse
    {
        $request->validate([
            'license_plate' => 'required|string|max:20',
            'vehicle_type_id' => 'required|exists:vehicle_types,id',
            'lost_fee' => 'required|numeric|min:0',
            'payment_method' => 'required|string|max:50',
            'payment_method_id' => 'nullable|exists:payment_methods,id',
            'reference_number' => 'nullable|string|max:100',
            'notes' => 'nullable|string|max:500',
        ]);

        $user = $request->user();
        $parkingId = $user->parking_id ?? 1;
        $plate = strtoupper(trim($request->license_plate));

        // 1. Buscar si había un registro activo adentro
        $entry = VehicleEntry::where('parking_id', $parkingId)
            ->where('license_plate', $plate)
            ->where('status', 'inside')
            ->first();

        $now = now();

        if (!$entry) {
            $ticketCode = 'LOST-' . now()->format('Ymd') . '-' . rand(1000, 9999);
            $entry = VehicleEntry::create([
                'parking_id' => $parkingId,
                'vehicle_type_id' => $request->vehicle_type_id,
                'user_id' => $user->id,
                'ticket_code' => $ticketCode,
                'license_plate' => $plate,
                'entry_time' => $now,
                'status' => 'exited',
                'notes' => 'Ticket extraviado cobrado directamente. ' . ($request->notes ?? ''),
            ]);
            $durationMinutes = 0;
        } else {
            $durationMinutes = (int) $entry->entry_time->diffInMinutes($now);
            $entry->update(['status' => 'exited']);
        }

        $totalPaid = (float) $request->lost_fee;

        $exit = VehicleExit::create([
            'vehicle_entry_id' => $entry->id,
            'parking_id' => $parkingId,
            'user_id' => $user->id,
            'exit_time' => $now,
            'duration_minutes' => $durationMinutes,
            'calculated_amount' => $totalPaid,
            'discount_amount' => 0.00,
            'total_paid' => $totalPaid,
            'payment_method' => $request->payment_method,
            'payment_method_id' => $request->payment_method_id,
            'reference_number' => $request->reference_number,
            'notes' => '[TICKET EXTRAVIADO DIRECTO] ' . ($request->notes ?? ''),
        ]);

        $hours = intdiv($durationMinutes, 60);
        $mins = $durationMinutes % 60;

        return response()->json([
            'success' => true,
            'message' => 'Cobro por ticket extraviado registrado exitosamente.',
            'data' => [
                'exit_id' => $exit->id,
                'ticket_code' => $entry->ticket_code,
                'license_plate' => $entry->license_plate,
                'vehicle_type' => $entry->vehicleType->name ?? 'Vehículo',
                'entry_time' => $entry->entry_time->format('Y-m-d H:i:s'),
                'exit_time' => $exit->exit_time->format('Y-m-d H:i:s'),
                'duration_formatted' => $durationMinutes > 0 ? "{$hours}h {$mins}m" : 'Estadía no registrada (Extravío)',
                'calculated_amount' => $totalPaid,
                'discount' => 0.00,
                'penalty_amount' => $totalPaid,
                'total_paid' => $totalPaid,
                'payment_method' => $exit->payment_method,
                'currency' => $entry->parking->currency_symbol ?? 'Bs. ',
                'cashier' => $user->name,
                'is_lost_ticket' => true,
                'receipt_header' => $entry->parking->receipt_header,
                'receipt_footer' => 'COMPROBANTE ESPECIAL DE TICKET EXTRAVIADO',
                'ticket_url' => url("/tickets/{$entry->ticket_code}"),
            ],
        ]);
    }
}

