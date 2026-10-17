<?php

use App\Http\Controllers\TicketWebController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Comprobante / Ticket imprimible a PDF y vista web pública con código QR
Route::get('/tickets/{code}', [TicketWebController::class, 'show'])->name('tickets.show');
