<?php

namespace Database\Seeders;

use App\Models\Company;
use App\Models\Parking;
use App\Models\User;
use App\Models\VehicleEntry;
use App\Models\VehicleExit;
use App\Models\VehicleType;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Empresa SaaS
        $company = Company::create([
            'name' => 'ParkinGo Solutions S.A.S.',
            'document_number' => 'J-12345678-9',
            'phone' => '+58 412 1234567',
            'address' => 'Av. Principal Empresarial #45',
            'status' => 'active',
            'subscription_plan' => 'pro',
            'subscription_expires_at' => now()->addYear(),
        ]);

        // 2. Sucursal de Parqueo
        $parking = Parking::create([
            'company_id' => $company->id,
            'name' => 'Estacionamiento Central ParkinGo',
            'address' => 'Centro Comercial Gran Plaza, Nivel Sótano',
            'phone' => '+58 212 9876543',
            'total_capacity' => 50,
            'currency_symbol' => '$',
            'receipt_header' => "PARKINGO CENTRAL\nRIF: J-12345678-9\n¡BIENVENIDO!",
            'receipt_footer' => "Gracias por su preferencia.\nConserve su ticket. Tarifa mínima 1 hora.\nNo nos hacemos responsables por objetos de valor no declarados.",
        ]);

        // 3. Usuarios
        $admin = User::create([
            'company_id' => $company->id,
            'parking_id' => $parking->id,
            'name' => 'Daniel Luna',
            'email' => 'daniel@parkingo.com',
            'role' => 'admin',
            'phone' => '+591 70000000',
            'pin_code' => '1234',
            'password' => Hash::make('password123'),
        ]);

        $adminLegacy = User::create([
            'company_id' => $company->id,
            'parking_id' => $parking->id,
            'name' => 'Daniel Luna',
            'email' => 'admin@parkingo.com',
            'role' => 'admin',
            'phone' => '+591 70000001',
            'pin_code' => '1234',
            'password' => Hash::make('password123'),
        ]);

        $operator = User::create([
            'company_id' => $company->id,
            'parking_id' => $parking->id,
            'name' => 'Carlos Operador',
            'email' => 'operador@parkingo.com',
            'role' => 'operator',
            'phone' => '+58 414 9998877',
            'pin_code' => '0000',
            'password' => Hash::make('password123'),
        ]);

        // 4. Tipos de Vehículos
        $moto = VehicleType::create([
            'parking_id' => $parking->id,
            'name' => 'Motocicleta',
            'icon' => 'motorcycle',
            'rate_per_hour' => 3.00,
            'rate_per_fraction' => 1.00,
            'fraction_minutes' => 15,
            'grace_period_minutes' => 15,
            'flat_day_rate' => 15.00,
            'is_active' => true,
        ]);

        $car = VehicleType::create([
            'parking_id' => $parking->id,
            'name' => 'Automóvil',
            'icon' => 'car',
            'rate_per_hour' => 5.00,
            'rate_per_fraction' => 1.50,
            'fraction_minutes' => 15,
            'grace_period_minutes' => 15,
            'flat_day_rate' => 25.00,
            'is_active' => true,
        ]);

        $other = VehicleType::create([
            'parking_id' => $parking->id,
            'name' => 'Camioneta / Otro',
            'icon' => 'truck',
            'rate_per_hour' => 7.00,
            'rate_per_fraction' => 2.00,
            'fraction_minutes' => 15,
            'grace_period_minutes' => 15,
            'flat_day_rate' => 35.00,
            'is_active' => true,
        ]);

        // 5. Entradas activas (Vehículos adentro como en el mockup)
        $vehiclesInside = [
            ['plate' => 'B 1234 KLM', 'type' => $moto->id, 'mins_ago' => 155],
            ['plate' => 'B 5678 DEF', 'type' => $car->id, 'mins_ago' => 124],
            ['plate' => 'B 9012 GHI', 'type' => $moto->id, 'mins_ago' => 108],
            ['plate' => 'B 3456 JKL', 'type' => $car->id, 'mins_ago' => 71],
            ['plate' => 'B 7890 MNO', 'type' => $moto->id, 'mins_ago' => 56],
            ['plate' => 'A 2468 XYZ', 'type' => $car->id, 'mins_ago' => 45],
            ['plate' => 'C 1357 PQR', 'type' => $other->id, 'mins_ago' => 30],
            ['plate' => 'M 9988 TUV', 'type' => $moto->id, 'mins_ago' => 18],
        ];

        foreach ($vehiclesInside as $idx => $v) {
            VehicleEntry::create([
                'parking_id' => $parking->id,
                'vehicle_type_id' => $v['type'],
                'user_id' => $operator->id,
                'ticket_code' => sprintf('TKT-%s-%04d', now()->format('Ymd'), $idx + 1),
                'license_plate' => $v['plate'],
                'entry_time' => now()->subMinutes($v['mins_ago']),
                'status' => 'inside',
                'notes' => 'Ingreso normal por garita 1',
            ]);
        }

        // 6. Transacciones completadas hoy (Vehículos que ya salieron)
        $completedExits = [
            ['plate' => 'B 9900 AA', 'type' => $moto, 'duration' => 60, 'amount' => 3.00, 'method' => 'cash'],
            ['plate' => 'B 1122 BB', 'type' => $car, 'duration' => 120, 'amount' => 10.00, 'method' => 'cash'],
            ['plate' => 'B 3344 CC', 'type' => $moto, 'duration' => 90, 'amount' => 5.00, 'method' => 'e_wallet'],
            ['plate' => 'B 5566 DD', 'type' => $car, 'duration' => 150, 'amount' => 13.00, 'method' => 'card'],
        ];

        foreach ($completedExits as $i => $item) {
            $entry = VehicleEntry::create([
                'parking_id' => $parking->id,
                'vehicle_type_id' => $item['type']->id,
                'user_id' => $operator->id,
                'ticket_code' => sprintf('TKT-%s-%04d', now()->format('Ymd'), 100 + $i),
                'license_plate' => $item['plate'],
                'entry_time' => now()->subMinutes($item['duration'] + 60),
                'status' => 'exited',
                'notes' => 'Completado',
            ]);

            VehicleExit::create([
                'vehicle_entry_id' => $entry->id,
                'parking_id' => $parking->id,
                'user_id' => $operator->id,
                'exit_time' => now()->subMinutes(60),
                'duration_minutes' => $item['duration'],
                'calculated_amount' => $item['amount'],
                'discount_amount' => 0.00,
                'total_paid' => $item['amount'],
                'payment_method' => $item['method'],
                'notes' => 'Salida normal',
            ]);
        }
    }
}
