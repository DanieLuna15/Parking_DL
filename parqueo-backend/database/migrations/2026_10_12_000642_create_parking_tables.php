<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Empresas (Tenants)
        Schema::create('companies', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('document_number')->nullable();
            $table->string('phone')->nullable();
            $table->string('address')->nullable();
            $table->string('logo_url')->nullable();
            $table->enum('status', ['active', 'inactive', 'suspended'])->default('active');
            $table->string('subscription_plan')->default('pro');
            $table->timestamp('subscription_expires_at')->nullable();
            $table->timestamps();
        });

        // 2. Garitas / Sucursales de Parqueo
        Schema::create('parkings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('company_id')->constrained('companies')->onDelete('cascade');
            $table->string('name');
            $table->string('address')->nullable();
            $table->string('phone')->nullable();
            $table->integer('total_capacity')->default(50);
            $table->string('currency_symbol')->default('$');
            $table->string('receipt_header')->nullable();
            $table->string('receipt_footer')->nullable();
            $table->timestamps();
        });

        // 3. Modificar tabla users para soporte multi-tenant y roles
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('company_id')->nullable()->after('id')->constrained('companies')->onDelete('set null');
            $table->foreignId('parking_id')->nullable()->after('company_id')->constrained('parkings')->onDelete('set null');
            $table->enum('role', ['superadmin', 'admin', 'operator'])->default('operator')->after('email');
            $table->string('pin_code', 10)->nullable()->after('password');
            $table->string('phone')->nullable()->after('pin_code');
        });

        // 4. Tipos de Vehículos y sus Tarifas
        Schema::create('vehicle_types', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parking_id')->constrained('parkings')->onDelete('cascade');
            $table->string('name'); // Motocicleta, Automóvil, Camioneta, etc.
            $table->string('icon')->default('car'); // motorcycle, car, truck, etc.
            $table->decimal('rate_per_hour', 10, 2)->default(10.00);
            $table->decimal('rate_per_fraction', 10, 2)->default(2.50);
            $table->integer('fraction_minutes')->default(15);
            $table->integer('grace_period_minutes')->default(15); // Minutos de tolerancia gratis
            $table->decimal('flat_day_rate', 10, 2)->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 5. Registro de Entradas de Vehículos
        Schema::create('vehicle_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('parking_id')->constrained('parkings')->onDelete('cascade');
            $table->foreignId('vehicle_type_id')->constrained('vehicle_types');
            $table->foreignId('user_id')->constrained('users'); // Operador de garita
            $table->string('ticket_code')->unique(); // Folio de ticket (ej. TKT-20261011-001)
            $table->string('license_plate', 20)->index();
            $table->dateTime('entry_time');
            $table->string('photo_path')->nullable();
            $table->text('notes')->nullable();
            $table->enum('status', ['inside', 'exited', 'cancelled'])->default('inside')->index();
            $table->timestamps();
        });

        // 6. Registro de Salidas y Transacciones de Cobro
        Schema::create('vehicle_exits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('vehicle_entry_id')->unique()->constrained('vehicle_entries')->onDelete('cascade');
            $table->foreignId('parking_id')->constrained('parkings')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users'); // Operador que cobró
            $table->dateTime('exit_time');
            $table->integer('duration_minutes');
            $table->decimal('calculated_amount', 10, 2);
            $table->decimal('discount_amount', 10, 2)->default(0.00);
            $table->decimal('total_paid', 10, 2);
            $table->enum('payment_method', ['cash', 'e_wallet', 'card'])->default('cash');
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('vehicle_exits');
        Schema::dropIfExists('vehicle_entries');
        Schema::dropIfExists('vehicle_types');

        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['company_id']);
            $table->dropForeign(['parking_id']);
            $table->dropColumn(['company_id', 'parking_id', 'role', 'pin_code', 'phone']);
        });

        Schema::dropIfExists('parkings');
        Schema::dropIfExists('companies');
    }
};
