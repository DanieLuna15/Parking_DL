<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EntryController;
use App\Http\Controllers\Api\ExitController;
use App\Http\Controllers\Api\PaymentMethodController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\VehicleTypeController;
use Illuminate\Support\Facades\Route;

// Versión 1 de la API
Route::prefix('v1')->group(function () {

    // Verificación de estado del servidor (Ping / Health check público)
    Route::get('/health', function () {
        return response()->json([
            'success' => true,
            'message' => 'ParkinGo API operativa',
            'timestamp' => now()->toIso8601String(),
        ]);
    });

    // Rutas públicas de autenticación
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::get('/auth/login', function () {
        return response()->json([
            'success' => false,
            'message' => 'No autenticado. Por favor envía el token Bearer en los encabezados.',
        ], 401);
    })->name('login');

    // Rutas protegidas por Sanctum
    Route::middleware('auth:sanctum')->group(function () {
        
        // Perfil y cierre de sesión
        Route::get('/auth/profile', [AuthController::class, 'profile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Dashboard métricas en vivo
        Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

        // Catálogo de tipos de vehículos y tarifas
        Route::get('/vehicle-types', [VehicleTypeController::class, 'index']);
        Route::post('/vehicle-types', [VehicleTypeController::class, 'store']);
        Route::put('/vehicle-types/{vehicleType}', [VehicleTypeController::class, 'update']);
        Route::delete('/vehicle-types/{vehicleType}', [VehicleTypeController::class, 'destroy']);

        // Registro de entradas y vehículos adentro
        Route::post('/entries', [EntryController::class, 'store']);
        Route::get('/entries', [EntryController::class, 'index']);

        // Cálculo de salida y confirmación de cobro
        Route::get('/exits/calculate', [ExitController::class, 'calculate']);
        Route::post('/exits/complete', [ExitController::class, 'complete']);
        Route::post('/exits/lost-ticket', [ExitController::class, 'completeLostTicket']);

        // Historial de transacciones
        Route::get('/transactions', [TransactionController::class, 'index']);

        // Reportes diarios y estadísticas
        Route::get('/reports/daily', [ReportController::class, 'daily']);

        // Módulo de Formas de Pago (Payment Methods)
        Route::get('/payment-methods', [PaymentMethodController::class, 'index']);
        Route::post('/payment-methods', [PaymentMethodController::class, 'store']);
        Route::put('/payment-methods/{id}', [PaymentMethodController::class, 'update']);
        Route::post('/payment-methods/{id}/upload-qr', [PaymentMethodController::class, 'uploadQr']);
        Route::patch('/payment-methods/{id}/toggle', [PaymentMethodController::class, 'toggle']);
        Route::delete('/payment-methods/{id}', [PaymentMethodController::class, 'destroy']);
    });
});
