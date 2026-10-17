<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PaymentMethod;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PaymentMethodController extends Controller
{
    /**
     * Listar métodos de pago del parqueo.
     */
    public function index(Request $request): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;
        $includeInactive = $request->boolean('all', false);

        $query = PaymentMethod::where('parking_id', $parkingId)
            ->orderBy('order', 'asc')
            ->orderBy('id', 'asc');

        if (!$includeInactive) {
            $query->where('is_active', true);
        }

        $methods = $query->get();

        return response()->json([
            'success' => true,
            'data' => $methods,
        ]);
    }

    /**
     * Crear nuevo método de pago.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'code' => 'nullable|string|max:50',
            'icon' => 'nullable|string|max:50',
            'instructions' => 'nullable|string|max:500',
            'bank_name' => 'nullable|string|max:100',
            'account_holder' => 'nullable|string|max:150',
            'account_number' => 'nullable|string|max:50',
            'phone_number' => 'nullable|string|max:30',
            'requires_reference' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'qr_image' => 'nullable|image|max:5120',
        ]);

        $parkingId = $request->user()->parking_id ?? 1;

        $qrPath = null;
        if ($request->hasFile('qr_image')) {
            $qrPath = $request->file('qr_image')->store('payment_methods', 'public');
        }

        $maxOrder = PaymentMethod::where('parking_id', $parkingId)->max('order') ?? 0;

        $method = PaymentMethod::create([
            'parking_id' => $parkingId,
            'name' => trim($request->name),
            'code' => $request->code ?? 'other',
            'icon' => $request->icon ?? 'payments',
            'instructions' => $request->instructions,
            'qr_image_path' => $qrPath,
            'bank_name' => $request->bank_name,
            'account_holder' => $request->account_holder,
            'account_number' => $request->account_number,
            'phone_number' => $request->phone_number,
            'requires_reference' => $request->boolean('requires_reference', false),
            'is_active' => $request->boolean('is_active', true),
            'order' => $maxOrder + 1,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Método de pago registrado exitosamente.',
            'data' => $method,
        ], 201);
    }

    /**
     * Actualizar método de pago existente.
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;
        $method = PaymentMethod::where('id', $id)
            ->where('parking_id', $parkingId)
            ->firstOrFail();

        $request->validate([
            'name' => 'sometimes|required|string|max:100',
            'code' => 'nullable|string|max:50',
            'icon' => 'nullable|string|max:50',
            'instructions' => 'nullable|string|max:500',
            'bank_name' => 'nullable|string|max:100',
            'account_holder' => 'nullable|string|max:150',
            'account_number' => 'nullable|string|max:50',
            'phone_number' => 'nullable|string|max:30',
            'requires_reference' => 'nullable|boolean',
            'is_active' => 'nullable|boolean',
            'qr_image' => 'nullable|image|max:5120',
        ]);

        $data = $request->only([
            'name',
            'code',
            'icon',
            'instructions',
            'bank_name',
            'account_holder',
            'account_number',
            'phone_number',
        ]);

        if ($request->has('requires_reference')) {
            $data['requires_reference'] = $request->boolean('requires_reference');
        }
        if ($request->has('is_active')) {
            $data['is_active'] = $request->boolean('is_active');
        }

        if ($request->hasFile('qr_image')) {
            if ($method->qr_image_path) {
                Storage::disk('public')->delete($method->qr_image_path);
            }
            $data['qr_image_path'] = $request->file('qr_image')->store('payment_methods', 'public');
        }

        $method->update($data);

        return response()->json([
            'success' => true,
            'message' => 'Método de pago actualizado exitosamente.',
            'data' => $method,
        ]);
    }

    /**
     * Subir o actualizar foto QR para un método de pago.
     */
    public function uploadQr(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'qr_image' => 'required|image|max:5120',
        ]);

        $parkingId = $request->user()->parking_id ?? 1;
        $method = PaymentMethod::where('id', $id)
            ->where('parking_id', $parkingId)
            ->firstOrFail();

        if ($method->qr_image_path) {
            Storage::disk('public')->delete($method->qr_image_path);
        }

        $path = $request->file('qr_image')->store('payment_methods', 'public');
        $method->update(['qr_image_path' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Imagen QR actualizada con éxito.',
            'data' => $method,
        ]);
    }

    /**
     * Alternar estado activo / inactivo.
     */
    public function toggle(Request $request, int $id): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;
        $method = PaymentMethod::where('id', $id)
            ->where('parking_id', $parkingId)
            ->firstOrFail();

        $method->update(['is_active' => !$method->is_active]);

        return response()->json([
            'success' => true,
            'message' => $method->is_active ? 'Método de pago activado.' : 'Método de pago desactivado.',
            'data' => $method,
        ]);
    }

    /**
     * Eliminar método de pago.
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $parkingId = $request->user()->parking_id ?? 1;
        $method = PaymentMethod::where('id', $id)
            ->where('parking_id', $parkingId)
            ->firstOrFail();

        if ($method->qr_image_path) {
            Storage::disk('public')->delete($method->qr_image_path);
        }

        $method->delete();

        return response()->json([
            'success' => true,
            'message' => 'Método de pago eliminado correctamente.',
        ]);
    }
}
