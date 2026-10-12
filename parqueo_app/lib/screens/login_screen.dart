import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _emailController = TextEditingController(text: 'daniel@parkingo.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final result = await ApiService().login(email: email, password: password);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Credenciales incorrectas';
      });
    }
  }

  void _loginAsDemo() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icono / Logo
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ParkinGo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Títulos
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bienvenido de nuevo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Inicia sesión para continuar en el sistema',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Mensaje de error
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Campo Usuario / Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico / Usuario',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Contraseña
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Recordarme y Olvidé contraseña
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setState(() => _rememberMe = val ?? true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recordarme',
                        style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botón Iniciar Sesión
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Iniciar Sesión'),
              ),
              const SizedBox(height: 18),

              // Divisor 'o' (Mockup 2)
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      'o',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.cardBorder)),
                ],
              ),
              const SizedBox(height: 18),

              // Botón Continuar con Google (Mockup 2)
              OutlinedButton(
                onPressed: () {
                  _simulateGoogleLogin();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEA4335), // Rojo Google
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Continuar con Google',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botón Huella Digital (Biometría si ya ha iniciado sesión)
              OutlinedButton.icon(
                onPressed: () {
                  _handleBiometricAuth();
                },
                icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 26),
                label: const Text(
                  'Ingresar con Huella Digital',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primaryLight, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: AppColors.primarySoft,
                ),
              ),
              const SizedBox(height: 10),

              // Acceso Rápido Demo
              TextButton(
                onPressed: _loginAsDemo,
                child: const Text(
                  'Modo Demostración / Offline',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),

              // Botón Configuración de Servidor
              TextButton.icon(
                onPressed: _showServerConfigDialog,
                icon: const Icon(Icons.settings_ethernet_rounded, size: 16, color: AppColors.primary),
                label: Text(
                  'Servidor: ${ApiService().baseUrl.replaceAll('http://', '').replaceAll('/api/v1', '')}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _simulateGoogleLogin() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      setState(() => _isLoading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autenticado exitosamente con Google: daniel.luna@gmail.com'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  Future<void> _handleBiometricAuth() async {
    try {
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;

      if (!isDeviceSupported && !canCheckBiometrics) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu teléfono no cuenta con sensor biométrico o no está habilitado.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes huellas registradas en los ajustes de seguridad de tu teléfono Android.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Invoca el sensor de huella nativo del sistema operativo Android (BiometricPrompt)
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Escanea tu huella dactilar para acceder a ParkinGo',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Acceso con Huella Digital',
            biometricHint: 'Coloca tu dedo en el sensor',
            cancelButton: 'Cancelar',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        if (!mounted) return;
        setState(() => _isLoading = true);

        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final result = await ApiService().login(
          email: email.isNotEmpty ? email : 'daniel@parkingo.com',
          password: password.isNotEmpty ? password : 'password123',
        );

        setState(() => _isLoading = false);
        if (!mounted) return;

        if (result['success'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Huella verificada con éxito! Bienvenido a ParkinGo.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al iniciar sesión tras validar huella'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code != 'auth_in_progress' && e.code != 'canceled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aviso de sensor de huella: ${e.message ?? e.code}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar huella: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ApiService().baseUrl);
    bool isTesting = false;
    String? statusMessage;
    Color statusColor = AppColors.textSecondary;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.dns_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Servidor Backend API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona la dirección según cómo tengas conectado tu celular:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Cable USB (127.0.0.1)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          controller.text = 'http://127.0.0.1:8000/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Wi-Fi PC (192.168.0.150)', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        setDialogState(() {
                          controller.text = 'http://192.168.0.150:8000/api/v1';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'URL Base de la API',
                    hintText: 'http://192.168.0.150:8000/api/v1',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    statusMessage!,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: isTesting
                  ? null
                  : () async {
                      setDialogState(() {
                        isTesting = true;
                        statusMessage = 'Probando conexión...';
                        statusColor = AppColors.primary;
                      });
                      await ApiService().setBaseUrl(controller.text);
                      final ok = await ApiService().testConnection();
                      setDialogState(() {
                        isTesting = false;
                        if (ok) {
                          statusMessage = '✅ ¡Conexión con Laravel exitosa!';
                          statusColor = AppColors.success;
                        } else {
                          statusMessage = '❌ No se pudo conectar. Verifica que php artisan serve esté corriendo.';
                          statusColor = AppColors.error;
                        }
                      });
                    },
              child: isTesting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Probar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService().setBaseUrl(controller.text);
                if (mounted) setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Servidor configurado: ${controller.text}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
