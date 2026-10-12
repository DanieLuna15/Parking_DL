import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

class ScannerService {
  static final ScannerService _instance = ScannerService._internal();
  factory ScannerService() => _instance;
  ScannerService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Abre la cámara para capturar y reconocer la placa de un vehículo con Google ML Kit OCR
  Future<String?> scanLicensePlate(BuildContext context) async {
    final source = await _selectSourceDialog(context, title: 'Escanear Placa de Vehículo');
    if (source == null) return null;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image == null) return null;

      if (!context.mounted) return null;
      _showLoadingDialog(context, 'Reconociendo placa con IA...');

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (context.mounted) {
        Navigator.pop(context); // Cierra diálogo de carga
      }

      final candidates = _extractPlateCandidates(recognizedText.text);

      if (candidates.isEmpty) {
        if (context.mounted) {
          _showNoResultsDialog(context, recognizedText.text);
        }
        return null;
      }

      if (candidates.length == 1) {
        return candidates.first;
      }

      // Si hay varios candidatos, permitir al usuario elegir el más preciso
      if (context.mounted) {
        return await _pickCandidateDialog(context, candidates);
      }

      return candidates.first;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear con la cámara: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  /// Escanea código de barras o QR de un ticket térmico de estacionamiento
  Future<String?> scanTicketCode(BuildContext context) async {
    final source = await _selectSourceDialog(context, title: 'Escanear Ticket de Salida');
    if (source == null) return null;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image == null) return null;

      if (!context.mounted) return null;
      _showLoadingDialog(context, 'Leyendo código de ticket...');

      final inputImage = InputImage.fromFilePath(image.path);

      // 1. Intentar leer Código de Barras / QR con ML Kit
      final barcodeScanner = BarcodeScanner(formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.dataMatrix,
      ]);
      final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);
      await barcodeScanner.close();

      if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
        if (context.mounted) Navigator.pop(context);
        return barcodes.first.rawValue!.trim();
      }

      // 2. Si no es código de barras, intentar leer texto OCR del ticket (ej: "TKT-20261011-0001" o placa)
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (context.mounted) Navigator.pop(context);

      // Buscar coincidencia de formato TKT o similar
      final tktRegex = RegExp(r'TKT-[A-Z0-9-]+', caseSensitive: false);
      final match = tktRegex.firstMatch(recognizedText.text);
      if (match != null) {
        return match.group(0);
      }

      // O candidato de placa
      final candidates = _extractPlateCandidates(recognizedText.text);
      if (candidates.isNotEmpty) {
        return candidates.first;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se detectó un código de barras o ticket válido en la foto.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al escanear ticket: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return null;
    }
  }

  /// Limpia y filtra candidatos de placas de vehículos
  List<String> _extractPlateCandidates(String rawText) {
    final List<String> candidates = [];
    final lines = rawText.split('\n');

    // Palabras ignoradas (marcas de auto, países, palabras comunes)
    final ignoredWords = {
      'TOYOTA', 'NISSAN', 'HONDA', 'HYUNDAI', 'CHEVROLET', 'SUZUKI', 'FORD',
      'MITSUBISHI', 'KIA', 'VOLKSWAGEN', 'BOLIVIA', 'PERU', 'CHILE', 'ARGENTINA',
      'COLOMBIA', 'MEXICO', 'ESTACIONAMIENTO', 'PARKING', 'CENTRAL', 'PARKINGO',
      'ENTRADA', 'SALIDA', 'TICKET', 'HORA', 'FECHA', 'AUTO', 'MOTO'
    };

    for (var line in lines) {
      // Normalizar texto
      final clean = line.replaceAll(RegExp(r'[^A-Za-z0-9\s-]'), '').trim().toUpperCase();
      if (clean.length < 3 || clean.length > 12) continue;

      if (ignoredWords.contains(clean)) continue;

      // Verificar que contenga al menos un número o tenga formato de placa
      final hasDigits = clean.contains(RegExp(r'[0-9]'));
      final hasLetters = clean.contains(RegExp(r'[A-Za-z]'));

      // Formato típico de placas latinoamericanas/internacionales:
      // Ejemplos: "1234 ABC", "ABC 1234", "B 1234 KLM", "4567-XYZ", "7890TUV"
      if (hasDigits && (hasLetters || clean.length >= 4)) {
        if (!candidates.contains(clean)) {
          candidates.add(clean);
        }
      }
    }

    // Si no encontró líneas limpias pero hay texto corto que parece placa
    if (candidates.isEmpty) {
      final words = rawText.replaceAll(RegExp(r'[^A-Za-z0-9\s]'), ' ').split(RegExp(r'\s+'));
      for (var w in words) {
        final upper = w.toUpperCase().trim();
        if (upper.length >= 4 && upper.length <= 8 && upper.contains(RegExp(r'[0-9]'))) {
          if (!ignoredWords.contains(upper) && !candidates.contains(upper)) {
            candidates.add(upper);
          }
        }
      }
    }

    return candidates;
  }

  Future<ImageSource?> _selectSourceDialog(BuildContext context, {required String title}) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Cámara en Vivo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Tomar foto directa a la placa'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                ),
                title: const Text('Galería de Imágenes', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Seleccionar foto existente'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }

  void _showNoResultsDialog(BuildContext context, String detectedText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Placa no detectada'),
          ],
        ),
        content: Text(
          detectedText.trim().isNotEmpty
              ? 'Se detectó texto pero no parece una placa:\n"$detectedText"\n\nPor favor intenta acercar más la cámara a la placa o escríbela manualmente.'
              : 'No se detectó ningún texto en la fotografía. Intenta enfocar con mejor iluminación.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickCandidateDialog(BuildContext context, List<String> candidates) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Selecciona la placa detectada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: candidates.map((c) => ListTile(
            leading: const Icon(Icons.pin_rounded, color: AppColors.primary),
            title: Text(c, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            onTap: () => Navigator.pop(ctx, c),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}
