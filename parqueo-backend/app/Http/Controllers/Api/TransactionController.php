<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\VehicleExit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    /**
     * Listado de transacciones de cobro con filtros (Today, This Week, This Month).
     */
    public function index(Request $request): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;
        $period = $request->query('period', 'today'); // today, week, month, all
        $search = $request->query('search');

        $query = VehicleExit::where('parking_id', $parkingId)
            ->with(['entry.vehicleType', 'user']);

        // Filtro por periodo
        switch ($period) {
            case 'today':
                $query->whereDate('exit_time', now()->toDateString());
                break;
            case 'week':
                $query->whereBetween('exit_time', [now()->startOfWeek(), now()->endOfWeek()]);
                break;
            case 'month':
                $query->whereMonth('exit_time', now()->month)
                      ->whereYear('exit_time', now()->year);
                break;
        }

        // Búsqueda por placa o folio de ticket
        if ($search) {
            $query->whereHas('entry', function ($q) use ($search) {
                $q->where('license_plate', 'like', "%{$search}%")
                  ->orWhere('ticket_code', 'like', "%{$search}%");
            });
        }

        $transactions = $query->orderBy('exit_time', 'desc')->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $transactions,
        ]);
    }
}
