import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/app_alert.dart';

enum ScannerTarget { plate, qrCode }

class FastCameraScannerScreen extends StatefulWidget {
  final ScannerTarget target;

  const FastCameraScannerScreen({
    super.key,
    this.target = ScannerTarget.plate,
  });

  @override
  State<FastCameraScannerScreen> createState() => _FastCameraScannerScreenState();
}

class _FastCameraScannerScreenState extends State<FastCameraScannerScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  String? _detectedResult;
  late ScannerTarget _currentTarget;

  late AnimationController _animController;
  Timer? _autoScanTimer;

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  @override
  void initState() {
    super.initState();
    _currentTarget = widget.target;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      // Seleccionar cámara trasera por defecto
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    final prev = _controller;
    await prev?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.medium, // Resolución óptima para escaneo veloz
      enableAudio: false,
    );

    _controller = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });

      // Iniciar ciclo de escaneo automático continuo cada 900ms
      _startAutoScanLoop();
    } catch (e) {
      debugPrint('Error al inicializar controlador de cámara: $e');
    }
  }

  void _startAutoScanLoop() {
    _autoScanTimer?.cancel();
    _autoScanTimer = Timer.periodic(const Duration(milliseconds: 950), (_) {
      if (_isInitialized && !_isProcessing && _detectedResult == null) {
        _processCurrentFrame();
      }
    });
  }

  Future<void> _processCurrentFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isProcessing || _detectedResult != null) return;

    _isProcessing = true;

    try {
      final XFile file = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);

      if (_currentTarget == ScannerTarget.plate) {
        final recognizedText = await _textRecognizer.processImage(inputImage);
        final plate = _extractPlate(recognizedText.text);
        if (plate != null) {
          _onFoundResult(plate);
        }
      } else {
        final barcodes = await _barcodeScanner.processImage(inputImage);
        if (barcodes.isNotEmpty) {
          final code = barcodes.first.rawValue ?? barcodes.first.displayValue;
          if (code != null && code.isNotEmpty) {
            _onFoundResult(code);
          }
        }
      }
    } catch (_) {
      // Ignorar errores de captura rápida y continuar el ciclo
    } finally {
      if (mounted) {
        _isProcessing = false;
      }
    }
  }

  String? _extractPlate(String text) {
    if (text.isEmpty) return null;

    final cleaned = text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\s-]'), '');
    final lines = cleaned.split('\n');

    // 1. Patrones estrictos de placa (ej: 1234ABC, 1234-ABC, ABC 1234, B 1234 KLM)
    final strictRegexes = [
      RegExp(r'\b\d{3,4}\s*[-]?\s*[A-Z]{3}\b'), // 1234ABC o 1234-ABC
      RegExp(r'\b[A-Z]{3}\s*[-]?\s*\d{3,4}\b'), // ABC1234
      RegExp(r'\b[A-Z]\s*\d{3,4}\s*[A-Z]{2,3}\b'), // B 1234 KLM
      RegExp(r'\b\d{4}\s*[A-Z]{3}\b'),
    ];

    for (final line in lines) {
      final trimmed = line.trim();
      for (final reg in strictRegexes) {
        final match = reg.firstMatch(trimmed);
        if (match != null) {
          return match.group(0)!.replaceAll(' ', '').replaceAll('-', '');
        }
      }
    }

    // 2. Patrón general de placa estándar (5 a 8 caracteres alfanuméricos)
    for (final line in lines) {
      final t = line.replaceAll(' ', '').replaceAll('-', '').trim();
      if (t.length >= 5 && t.length <= 8) {
        final hasLetters = RegExp(r'[A-Z]').hasMatch(t);
        final hasDigits = RegExp(r'[0-9]').hasMatch(t);
        if (hasLetters && hasDigits) {
          return t;
        }
      }
    }

    return null;
  }

  void _onFoundResult(String result) {
    _autoScanTimer?.cancel();
    HapticFeedback.heavyImpact();

    setState(() {
      _detectedResult = result;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      if (_currentTarget == ScannerTarget.plate) {
        final recognized = await _textRecognizer.processImage(inputImage);
        final plate = _extractPlate(recognized.text);
        if (plate != null) {
          _onFoundResult(plate);
          return;
        }
      } else {
        final barcodes = await _barcodeScanner.processImage(inputImage);
        if (barcodes.isNotEmpty) {
          final code = barcodes.first.rawValue;
          if (code != null) {
            _onFoundResult(code);
            return;
          }
        }
      }

      if (mounted) {
        AppAlert.warning(
          context,
          'No se detectó ninguna placa clara en la imagen seleccionada.',
          title: 'Sin coincidencias',
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _animController.dispose();
    _controller?.dispose();
    _textRecognizer.close();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Vista previa de la cámara en vivo
          if (_isInitialized && _controller != null)
            Center(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Iniciando cámara rápida...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),

          // 2. Capa oscura con ventana de escaneo (Retícula)
          _buildScannerOverlay(),

          // 3. Barra Superior (Volver, Flash, Switch Cámara)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // Selector de Modo (Placa vs QR)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeChip(
                            label: '🚘 Placa',
                            isSelected: _currentTarget == ScannerTarget.plate,
                            onTap: () {
                              setState(() => _currentTarget = ScannerTarget.plate);
                            },
                          ),
                          _buildModeChip(
                            label: '📷 Ticket QR',
                            isSelected: _currentTarget == ScannerTarget.qrCode,
                            onTap: () {
                              setState(() => _currentTarget = ScannerTarget.qrCode);
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                            color: _isFlashOn ? Colors.amber : Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                        if (_cameras.length > 1)
                          IconButton(
                            icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
                            onPressed: _switchCamera,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Barra Inferior con botón de disparo manual y galería
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_detectedResult != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.4),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            '¡Detectado: $_detectedResult!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Galería
                      IconButton(
                        icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                        onPressed: _pickFromGallery,
                        tooltip: 'Elegir de Galería',
                      ),

                      // Botón Disparador Instantáneo
                      GestureDetector(
                        onTap: () => _processCurrentFrame(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                          child: Center(
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : const Icon(Icons.bolt_rounded, color: Colors.white, size: 38),
                          ),
                        ),
                      ),

                      // Placeholder o ayuda
                      IconButton(
                        icon: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 28),
                        onPressed: () {
                          AppAlert.info(
                            context,
                            'Apunta la cámara a la placa del vehículo. El escáner la detectará y leerá automáticamente en tiempo real.',
                            title: 'Ayuda del Escáner',
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentTarget == ScannerTarget.plate
                        ? 'Detección automática en vivo activa'
                        : 'Apunta al código QR o de barras',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    final size = MediaQuery.of(context).size;
    final isPlate = _currentTarget == ScannerTarget.plate;

    // Dimensiones de la caja de escaneo
    final frameWidth = size.width * 0.85;
    final frameHeight = isPlate ? 140.0 : frameWidth;

    return Stack(
      children: [
        // Ventana central
        Center(
          child: Container(
            width: frameWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _detectedResult != null
                    ? AppColors.success
                    : AppColors.primaryLight,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_detectedResult != null
                          ? AppColors.success
                          : AppColors.primary)
                      .withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Esquinas destacadas
                ..._buildCorners(),

                // Línea láser animada de escaneo
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    return Positioned(
                      top: _animController.value * (frameHeight - 4),
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: _detectedResult != null
                              ? AppColors.success
                              : Colors.redAccent,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: (_detectedResult != null
                                      ? AppColors.success
                                      : Colors.redAccent)
                                  .withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Texto indicador encima de la retícula
        Positioned(
          top: (size.height / 2) - (frameHeight / 2) - 46,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isPlate
                    ? 'Enfoca la placa del vehículo aquí'
                    : 'Enfoca el código QR del ticket',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const size = 20.0;
    const thickness = 4.0;
    const color = Colors.white;

    return [
      // Top-Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
          ),
        ),
      ),

      // Top-Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
          ),
        ),
      ),

      // Bottom-Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
          ),
        ),
      ),

      // Bottom-Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          decoration: const BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
          ),
        ),
      ),
    ];
  }
}
