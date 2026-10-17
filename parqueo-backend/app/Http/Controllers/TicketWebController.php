<?php

namespace App\Http\Controllers;

use App\Models\VehicleEntry;
use Illuminate\Http\Request;

class TicketWebController extends Controller
{
    /**
     * Muestra la vista web del ticket para imprimir o guardar como PDF.
     */
    public function show(string $code)
    {
        $entry = VehicleEntry::where('ticket_code', $code)
            ->with(['parking', 'vehicleType', 'user', 'exit.user'])
            ->first();

        if (!$entry) {
            abort(404, 'Ticket no encontrado en el sistema');
        }

        $ticketUrl = url("/tickets/{$entry->ticket_code}");
        $qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=" . urlencode($ticketUrl);

        return view('ticket', compact('entry', 'ticketUrl', 'qrUrl'));
    }
}
