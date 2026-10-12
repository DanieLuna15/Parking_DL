import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Configuraciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            _SettingsTile(
              icon: Icons.store_mall_directory_outlined,
              title: 'Información del Parqueo',
              subtitle: 'Nombre, dirección, teléfono y sucursal',
              onTap: () {
                _showInfoDialog(context, 'Información del Parqueo', 'Estacionamiento Central ParkinGo\nAv. Principal #45\nTel: +58 412 1234567\nCapacidad: 50 puestos');
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.price_change_outlined,
              title: 'Ajustes de Tarifas',
              subtitle: 'Precios por hora, fracción y tolerancia',
              onTap: () {
                _showInfoDialog(context, 'Tarifas Actuales', '• Motocicleta: \$3.00/h (Frac: \$1.00)\n• Automóvil: \$5.00/h (Frac: \$1.50)\n• Camión: \$7.00/h (Frac: \$2.00)\nTolerancia de cortesía: 15 minutos');
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.directions_car_outlined,
              title: 'Tipos de Vehículos',
              subtitle: 'Gestionar categorías de vehículos',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.print_outlined,
              title: 'Ajustes de Impresora',
              subtitle: 'Configuración Bluetooth / Impresora Térmica POS',
              onTap: () {
                _showPrinterDialog(context);
              },
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.cloud_sync_outlined,
              title: 'Respaldo de Datos',
              subtitle: 'Exportar transacciones y sincronización',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.lock_outline_rounded,
              title: 'Bloqueo de Pantalla',
              subtitle: 'PIN rápido o contraseña de cajero',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Tema de la Aplicación',
              subtitle: 'Modo claro / Modo oscuro',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'Acerca de ParkinGo',
              subtitle: 'Versión 1.0.0 (SaaS Edition)',
              onTap: () {
                _showInfoDialog(context, 'Acerca de ParkinGo', 'ParkinGo SaaS Parking Management\nVersión 1.0.0 Pro\nDesarrollado con Flutter & Laravel 11');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _showPrinterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Impresora Térmica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dispositivos Bluetooth vinculados:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.bluetooth_connected_rounded, color: AppColors.primary),
              title: Text('POS-58 Bluetooth', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Estado: Conectada (58mm)', style: TextStyle(fontSize: 12, color: AppColors.success)),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impresión de prueba enviada con éxito.')),
              );
            },
            child: const Text('Imprimir Prueba'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
