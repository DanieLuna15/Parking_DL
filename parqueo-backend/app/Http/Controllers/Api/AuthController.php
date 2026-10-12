<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Iniciar sesión con email y contraseña, o por PIN rápido.
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email' => 'required_without:pin_code|nullable|string',
            'password' => 'required_with:email|nullable|string',
            'pin_code' => 'required_without:email|nullable|string',
        ]);

        $user = null;

        if ($request->filled('pin_code')) {
            $user = User::where('pin_code', $request->pin_code)->first();
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'El código PIN ingresado es incorrecto.',
                ], 401);
            }
        } else {
            $user = User::where('email', $request->email)->first();

            if (!$user || !Hash::check($request->password, $user->password)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Credenciales de acceso incorrectas.',
                ], 401);
            }
        }

        // Cargar relaciones
        $user->load(['company', 'parking']);

        // Crear token de acceso
        $token = $user->createToken('parkingo_mobile_app')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Inicio de sesión exitoso.',
            'data' => [
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role,
                    'phone' => $user->phone,
                ],
                'company' => $user->company,
                'parking' => $user->parking,
            ],
        ]);
    }

    /**
     * Obtener datos del usuario autenticado.
     */
    public function profile(Request $request): JsonResponse
    {
        $user = $request->user()->load(['company', 'parking']);

        return response()->json([
            'success' => true,
            'data' => $user,
        ]);
    }

    /**
     * Cerrar sesión.
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Sesión cerrada correctamente.',
        ]);
    }
}
