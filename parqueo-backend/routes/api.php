<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EntryController;
use App\Http\Controllers\Api\ExitController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\VehicleTypeController;
use Illuminate\Support\Facades\Route;

// Versión 1 de la API
Route::prefix('v1')->group(function () {

    // Rutas públicas de autenticación
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Rutas protegidas por Sanctum
    Route::middleware('auth:sanctum')->group(function () {
        
        // Perfil y cierre de sesión
        Route::get('/auth/profile', [AuthController::class, 'profile']);
        Route::post('/auth/logout', [AuthController::class, 'logout']);

        // Dashboard métricas en vivo
        Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

        // Catálogo de tipos de vehículos y tarifas
        Route::get('/vehicle-types', [VehicleTypeController::class, 'index']);
        Route::put('/vehicle-types/{vehicleType}', [VehicleTypeController::class, 'update']);

        // Registro de entradas y vehículos adentro
        Route::post('/entries', [EntryController::class, 'store']);
        Route::get('/entries', [EntryController::class, 'index']);

        // Cálculo de salida y confirmación de cobro
        Route::get('/exits/calculate', [ExitController::class, 'calculate']);
        Route::post('/exits/complete', [ExitController::class, 'complete']);

        // Historial de transacciones
        Route::get('/transactions', [TransactionController::class, 'index']);

        // Reportes diarios y estadísticas
        Route::get('/reports/daily', [ReportController::class, 'daily']);
    });
});
