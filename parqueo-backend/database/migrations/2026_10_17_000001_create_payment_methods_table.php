<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        // 1. Tabla de Formas / Métodos de Pago
        Schema::dropIfExists('payment_methods');
        Schema::create('payment_methods', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parking_id')->constrained('parkings')->onDelete('cascade');
            $table->string('name'); // Ej. Efectivo, QR BCP, Tigo Money, Tarjeta POS
            $table->string('code')->default('cash'); // cash, e_wallet, card, transfer, other
            $table->string('icon')->default('payments'); // payments, qr_code, credit_card, account_balance
            $table->text('instructions')->nullable();
            $table->string('qr_image_path')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('account_holder')->nullable();
            $table->string('account_number')->nullable();
            $table->string('phone_number')->nullable();
            $table->boolean('requires_reference')->default(false);
            $table->boolean('is_active')->default(true);
            $table->integer('order')->default(0);
            $table->timestamps();
        });

        // 2. Modificar tabla vehicle_exits para admitir métodos dinámicos y número de referencia
        try {
            DB::statement("ALTER TABLE vehicle_exits MODIFY COLUMN payment_method VARCHAR(50) DEFAULT 'cash'");
        } catch (\Throwable $e) {}

        Schema::table('vehicle_exits', function (Blueprint $table) {
            if (!Schema::hasColumn('vehicle_exits', 'reference_number')) {
                $table->string('reference_number')->nullable()->after('payment_method');
            }
            if (!Schema::hasColumn('vehicle_exits', 'payment_method_id')) {
                $table->foreignId('payment_method_id')->nullable()->after('payment_method')->constrained('payment_methods')->onDelete('set null');
            }
        });

        // 3. Sembrar métodos predeterminados para los parkings existentes
        $parkings = DB::table('parkings')->get();
        foreach ($parkings as $parking) {
            DB::table('payment_methods')->insert([
                'parking_id' => $parking->id,
                'name' => 'Efectivo',
                'code' => 'cash',
                'icon' => 'payments',
                'instructions' => 'Cobro en billetes o monedas locales.',
                'bank_name' => null,
                'account_holder' => null,
                'account_number' => null,
                'phone_number' => null,
                'requires_reference' => false,
                'is_active' => true,
                'order' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('payment_methods')->insert([
                'parking_id' => $parking->id,
                'name' => 'Pago QR / Billetera Móvil',
                'code' => 'e_wallet',
                'icon' => 'qr_code',
                'instructions' => 'Muestre el código QR al cliente para escanear desde su aplicación bancaria o billetera móvil.',
                'bank_name' => 'Banco Central / Simple QR',
                'account_holder' => 'Administración ' . $parking->name,
                'account_number' => null,
                'phone_number' => $parking->phone ?? '70000000',
                'requires_reference' => true,
                'is_active' => true,
                'order' => 2,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('payment_methods')->insert([
                'parking_id' => $parking->id,
                'name' => 'Tarjeta Débito / Crédito (POS)',
                'code' => 'card',
                'icon' => 'credit_card',
                'instructions' => 'Pase la tarjeta por la terminal punto de venta (POS) y confirme la transacción.',
                'bank_name' => null,
                'account_holder' => null,
                'account_number' => null,
                'phone_number' => null,
                'requires_reference' => true,
                'is_active' => true,
                'order' => 3,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::table('payment_methods')->insert([
                'parking_id' => $parking->id,
                'name' => 'Transferencia Bancaria',
                'code' => 'transfer',
                'icon' => 'account_balance',
                'instructions' => 'Transferencia directa a cuenta corriente.',
                'bank_name' => 'Banco Principal',
                'account_holder' => 'Administración ' . $parking->name,
                'account_number' => '1000-29384-01',
                'phone_number' => null,
                'requires_reference' => true,
                'is_active' => true,
                'order' => 4,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        DB::statement('SET FOREIGN_KEY_CHECKS=1;');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('vehicle_exits', function (Blueprint $table) {
            $table->dropForeign(['payment_method_id']);
            $table->dropColumn(['payment_method_id', 'reference_number']);
        });

        Schema::dropIfExists('payment_methods');
    }
};
