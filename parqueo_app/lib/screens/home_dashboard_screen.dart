import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import 'vehicle_entry_screen.dart';
import 'vehicle_exit_screen.dart';
import 'vehicles_list_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'payment_methods_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToVehicles;
  final VoidCallback? onNavigateToReports;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateToVehicles,
    this.onNavigateToReports,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  bool _isLoading = true;
  int _vehiclesInside = 18;
  int _motorcyclesInside = 10;
  int _carsInside = 6;
  int _othersInside = 2;
  String _parkingName = 'Estacionamiento Central';
  String _userName = 'Daniel';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final rawName = await ApiService().getUserName();
    final firstName = rawName.isNotEmpty ? rawName.split(' ').first : 'Daniel';

    final result = await ApiService().getDashboardSummary();
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      setState(() {
        _userName = firstName;
        _vehiclesInside = data['vehicles_inside'] ?? 18;
        _parkingName = data['parking_name'] ?? 'Estacionamiento Central';
        final breakdown = data['breakdown'] as List? ?? [];
        for (var b in breakdown) {
          final icon = b['icon']?.toString().toLowerCase();
          final count = b['count'] ?? 0;
          if (icon == 'motorcycle') {
            _motorcyclesInside = count;
          } else if (icon == 'car') {
            _carsInside = count;
          } else {
            _othersInside = count;
          }
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header con Saludo y Notificación
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola, $_userName 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$_parkingName • Mantén el área de parqueo organizada',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textPrimary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 2. Tarjeta Azul Principal: "Vehículos Adentro" (Mockup 3)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehículos Adentro',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$_vehiclesInside',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.directions_car_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Desglose: Motocicletas, Autos, Otros
                      Row(
                        children: [
                          _VehicleCountBadge(
                            icon: Icons.two_wheeler_rounded,
                            label: 'Motos',
                            count: _motorcyclesInside,
                          ),
                          const SizedBox(width: 8),
                          _VehicleCountBadge(
                            icon: Icons.directions_car_rounded,
                            label: 'Autos',
                            count: _carsInside,
                          ),
                          const SizedBox(width: 8),
                          _VehicleCountBadge(
                            icon: Icons.local_shipping_rounded,
                            label: 'Otros',
                            count: _othersInside,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Título de Acciones Rápidas
                const Text(
                  'Acciones Rápidas',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Cuadrícula de 6 Opciones (Mockup 3)
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    _QuickActionButton(
                      icon: Icons.login_rounded,
                      label: 'Entrada',
                      color: const Color(0xFF10B981), // Verde
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VehicleEntryScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.logout_rounded,
                      label: 'Salida',
                      color: const Color(0xFFEF4444), // Rojo
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VehicleExitScreen()),
                        ).then((_) => _loadDashboardData());
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.directions_car_outlined,
                      label: 'Vehículos',
                      color: const Color(0xFF3B82F6), // Azul
                      onTap: () {
                        if (widget.onNavigateToVehicles != null) {
                          widget.onNavigateToVehicles!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VehiclesListScreen()),
                          );
                        }
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: 'Transacciones',
                      color: const Color(0xFFF59E0B), // Naranja
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                        );
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reportes',
                      color: const Color(0xFF8B5CF6), // Morado
                      onTap: () {
                        if (widget.onNavigateToReports != null) {
                          widget.onNavigateToReports!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReportsScreen()),
                          );
                        }
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.settings_outlined,
                      label: 'Ajustes',
                      color: const Color(0xFF64748B), // Slate / Gris
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 5. Banner de Acceso Rápido a Formas de Pago & QR
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Formas de Pago y Cobro QR',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Configura tus métodos de cobro, cuentas y QR',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleCountBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _VehicleCountBadge({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 5),
            Text(
              '$label: $count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
