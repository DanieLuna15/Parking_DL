import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/api_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Barra de estado transparente y estilizada
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Inicializar servicio de API
  await ApiService().init();

  runApp(const ParkinGoApp());
}

class ParkinGoApp extends StatelessWidget {
  const ParkinGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkinGo - Gestión de Parqueos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ApiService().isAuthenticated
          ? const MainNavigationScreen()
          : const OnboardingScreen(),
    );
  }
}
