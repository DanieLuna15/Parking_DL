import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Daniel Luna';
  String _userEmail = 'daniel@parkingo.com';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await ApiService().getUserData();
    if (data != null) {
      setState(() {
        _userName = data['name'] ?? 'Daniel Luna';
        _userEmail = data['email'] ?? 'daniel@parkingo.com';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // 1. Avatar con badge de cámara (Mockup 10)
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 54,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Nombre y Rol
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userEmail,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Administrador de Parqueo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 3. Menú de opciones (Mockup 10)
              _ProfileOption(
                icon: Icons.person_outline_rounded,
                title: 'Editar Perfil',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ProfileOption(
                icon: Icons.lock_outline_rounded,
                title: 'Cambiar Contraseña',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ProfileOption(
                icon: Icons.notifications_none_rounded,
                title: 'Ajustes de Notificaciones',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ProfileOption(
                icon: Icons.help_outline_rounded,
                title: 'Ayuda y Soporte Técnico',
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _ProfileOption(
                icon: Icons.info_outline_rounded,
                title: 'Acerca de ParkinGo',
                onTap: () {},
              ),
              const SizedBox(height: 20),

              // 4. Botón Cerrar Sesión (Rojo)
              InkWell(
                onTap: () async {
                  await ApiService().logout();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
