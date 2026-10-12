import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'home_dashboard_screen.dart';
import 'vehicles_list_screen.dart';
import 'reports_screen.dart';
import 'profile_screen.dart';
import 'vehicle_entry_screen.dart';
import 'vehicle_exit_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Operación Rápida',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.login_rounded, color: AppColors.success, size: 24),
              ),
              title: const Text('Registrar Entrada de Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Generar ticket y asignar espacio', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleEntryScreen()),
                );
              },
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
              ),
              title: const Text('Registrar Salida y Cobro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              subtitle: const Text('Escanear ticket o buscar por placa', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VehicleExitScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeDashboardScreen(
        onNavigateToVehicles: () => _onTabTapped(1),
        onNavigateToReports: () => _onTabTapped(2),
      ),
      const VehiclesListScreen(),
      const ReportsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionSheet,
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 12,
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.home_rounded,
              label: 'Inicio',
              isSelected: _currentIndex == 0,
              onTap: () => _onTabTapped(0),
            ),
            _NavBarItem(
              icon: Icons.directions_car_rounded,
              label: 'Vehículos',
              isSelected: _currentIndex == 1,
              onTap: () => _onTabTapped(1),
            ),
            const SizedBox(width: 48), // Espacio para el FloatingActionButton
            _NavBarItem(
              icon: Icons.bar_chart_rounded,
              label: 'Reportes',
              isSelected: _currentIndex == 2,
              onTap: () => _onTabTapped(2),
            ),
            _NavBarItem(
              icon: Icons.person_rounded,
              label: 'Perfil',
              isSelected: _currentIndex == 3,
              onTap: () => _onTabTapped(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
