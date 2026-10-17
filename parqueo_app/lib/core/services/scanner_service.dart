import 'package:flutter/material.dart';
import '../../screens/fast_camera_scanner_screen.dart';

class ScannerService {
  static final ScannerService _instance = ScannerService._internal();
  factory ScannerService() => _instance;
  ScannerService._internal();

  /// Abre la cámara en vivo integrada de alta velocidad para reconocer la placa
  Future<String?> scanLicensePlate(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const FastCameraScannerScreen(target: ScannerTarget.plate),
      ),
    );
    return result;
  }

  /// Abre la cámara en vivo para escanear código QR o de barras de un ticket
  Future<String?> scanTicketCode(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const FastCameraScannerScreen(target: ScannerTarget.qrCode),
      ),
    );
    return result;
  }
}
