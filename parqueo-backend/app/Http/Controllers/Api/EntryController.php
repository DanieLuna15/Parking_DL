<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehicleEntry;
use App\Models\VehicleType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class EntryController extends Controller
{
    /**
     * Registrar nuevo ingreso de vehículo (Vehicle Entry).
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'license_plate' => 'required|string|max:20',
            'vehicle_type_id' => 'required|exists:vehicle_types,id',
            'notes' => 'nullable|string|max:500',
            'photo' => 'nullable|image|max:5120', // Foto de hasta 5MB opcional
        ]);

        $user = $request->user();
        $parkingId = $user->parking_id ?? 1;
        $plate = strtoupper(trim($request->license_plate));

        // 1. Validar si el vehículo ya está adentro
        $alreadyInside = VehicleEntry::where('parking_id', $parkingId)
            ->where('license_plate', $plate)
            ->where('status', 'inside')
            ->first();

        if ($alreadyInside) {
            return response()->json([
                'success' => false,
                'message' => "El vehículo con placa {$plate} ya se encuentra registrado adentro con el ticket {$alreadyInside->ticket_code}.",
                'data' => $alreadyInside,
            ], 422);
        }

        // 2. Guardar foto opcional
        $photoPath = null;
        if ($request->hasFile('photo')) {
            $photoPath = $request->file('photo')->store('vehicle_entries', 'public');
        }

        // 3. Generar código de ticket único
        $ticketCode = VehicleEntry::generateTicketCode($parkingId);

        // 4. Crear registro
        $entry = VehicleEntry::create([
            'parking_id' => $parkingId,
            'vehicle_type_id' => $request->vehicle_type_id,
            'user_id' => $user->id,
            'ticket_code' => $ticketCode,
            'license_plate' => $plate,
            'entry_time' => now(),
            'photo_path' => $photoPath,
            'notes' => $request->notes,
            'status' => 'inside',
        ]);

        $entry->load(['vehicleType', 'parking', 'user']);

        return response()->json([
            'success' => true,
            'message' => 'Ingreso de vehículo registrado exitosamente.',
            'data' => [
                'entry' => $entry,
                'ticket' => [
                    'ticket_code' => $entry->ticket_code,
                    'license_plate' => $entry->license_plate,
                    'vehicle_type' => $entry->vehicleType->name,
                    'entry_time' => $entry->entry_time->format('Y-m-d H:i:s'),
                    'rate_per_hour' => $entry->vehicleType->rate_per_hour,
                    'parking_name' => $entry->parking->name,
                    'cashier' => $entry->user->name,
                    'header' => $entry->parking->receipt_header,
                    'footer' => $entry->parking->receipt_footer,
                ],
            ],
        ], 201);
    }

    /**
     * Listar vehículos actualmente adentro (Vehicles List / Inside).
     */
    public function index(Request $request): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;
        $status = $request->query('status', 'inside'); // inside, exited, all
        $search = $request->query('search');

        $query = VehicleEntry::where('parking_id', $parkingId)
            ->with(['vehicleType', 'exit', 'user']);

        if ($status !== 'all') {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('license_plate', 'like', "%{$search}%")
                  ->orWhere('ticket_code', 'like', "%{$search}%");
            });
        }

        $entries = $query->orderBy('entry_time', 'desc')->paginate(20);

        // Calcular duración en tiempo real para los que siguen adentro
        $entries->getCollection()->transform(function ($entry) {
            if ($entry->status === 'inside') {
                $now = now();
                $diffMinutes = (int) $entry->entry_time->diffInMinutes($now);
                $hours = intdiv($diffMinutes, 60);
                $mins = $diffMinutes % 60;
                $entry->duration_formatted = "{$hours}h {$mins}m";
                $entry->duration_minutes = $diffMinutes;
            } else if ($entry->exit) {
                $hours = intdiv($entry->exit->duration_minutes, 60);
                $mins = $entry->exit->duration_minutes % 60;
                $entry->duration_formatted = "{$hours}h {$mins}m";
                $entry->duration_minutes = $entry->exit->duration_minutes;
            }
            return $entry;
        });

        return response()->json([
            'success' => true,
            'data' => $entries,
        ]);
    }
}
