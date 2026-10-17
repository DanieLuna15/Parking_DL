import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/services/pdf_ticket_service.dart';
import '../core/services/scanner_service.dart';
import '../core/widgets/app_alert.dart';

class VehicleEntryScreen extends StatefulWidget {
  const VehicleEntryScreen({super.key});

  @override
  State<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends State<VehicleEntryScreen> {
  final _plateController = TextEditingController();
  final _notesController = TextEditingController();
  int _selectedTypeIndex = 1; // 0: Moto, 1: Auto, 2: Otro
  DateTime _entryDateTime = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  File? _evidencePhoto;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'id': 1, 'name': 'Motocicleta', 'icon': Icons.two_wheeler_rounded, 'rate': 3.0},
    {'id': 2, 'name': 'Automóvil', 'icon': Icons.directions_car_rounded, 'rate': 5.0},
    {'id': 3, 'name': 'Camioneta / Otro', 'icon': Icons.local_shipping_rounded, 'rate': 7.0},
  ];

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  IconData _getVehicleIcon(dynamic vehicleType) {
    if (vehicleType == null) return Icons.directions_car_rounded;
    String name = '';
    String icon = '';
    if (vehicleType is Map) {
      name = (vehicleType['name'] ?? '').toString().toLowerCase();
      icon = (vehicleType['icon'] ?? '').toString().toLowerCase();
    } else if (vehicleType is String) {
      name = vehicleType.toLowerCase();
    }

    if (icon == 'motorcycle' || name.contains('moto') || name.contains('scooter')) {
      return Icons.two_wheeler_rounded;
    } else if (icon == 'truck' || name.contains('camion') || name.contains('camión') || name.contains('pesado')) {
      return Icons.local_shipping_rounded;
    } else if (icon == 'bicycle' || name.contains('bici')) {
      return Icons.pedal_bike_rounded;
    } else if (icon == 'bus' || name.contains('bus') || name.contains('micro') || name.contains('colectivo')) {
      return Icons.directions_bus_rounded;
    } else if (icon == 'van' || name.contains('furgon') || name.contains('furgón') || name.contains('van')) {
      return Icons.airport_shuttle_rounded;
    }
    return Icons.directions_car_rounded;
  }

  Future<void> _loadVehicleTypes() async {
    final res = await ApiService().getVehicleTypes();
    if (res['success'] == true && res['data'] != null && (res['data'] as List).isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _vehicleTypes.clear();
        for (var item in res['data']) {
          _vehicleTypes.add({
            'id': item['id'],
            'name': item['name'],
            'icon': _getVehicleIcon(item),
            'rate': double.tryParse(item['rate_per_hour'].toString()) ?? 5.0,
          });
        }
        if (_selectedTypeIndex >= _vehicleTypes.length) {
          _selectedTypeIndex = 0;
        }
      });
    }
  }

  Future<void> _handleSaveEntry() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa o escanea la placa del vehículo.');
      AppAlert.warning(context, 'Por favor ingresa o escanea la placa del vehículo.', title: 'Placa Requerida');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final selectedTypeId = _vehicleTypes[_selectedTypeIndex]['id'] as int;
    final result = await ApiService().registerEntry(
      licensePlate: plate,
      vehicleTypeId: selectedTypeId,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      photoPath: _evidencePhoto?.path,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      _showSuccessDialog(result['data']?['ticket'] ?? {
        'ticket_code': 'TKT-${DateFormat('yyyyMMdd').format(DateTime.now())}-0099',
        'license_plate': plate,
        'vehicle_type': _vehicleTypes[_selectedTypeIndex]['name'],
        'entry_time': DateFormat('yyyy-MM-dd HH:mm').format(_entryDateTime),
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Error al registrar la entrada';
      });
      if (mounted) {
        AppAlert.error(context, result['message'] ?? 'Error al registrar la entrada');
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> ticket) {
    final ticketCode = ticket['ticket_code'] ?? 'TKT-001';
    final plate = ticket['license_plate'] ?? _plateController.text.trim();
    final vehicleType = ticket['vehicle_type'] ?? _vehicleTypes[_selectedTypeIndex]['name'];
    final entryTime = ticket['entry_time'] ?? DateFormat('yyyy-MM-dd HH:mm').format(_entryDateTime);
    final ratePerHour = (ticket['rate_per_hour'] ?? _vehicleTypes[_selectedTypeIndex]['rate'] ?? 5.0).toDouble();
    final cashier = ticket['cashier'] ?? 'Daniel Luna';
    final ticketUrl = ticket['ticket_url'] ?? '${ApiService().baseUrl.replaceAll('/api/v1', '')}/tickets/$ticketCode';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('¡Ingreso Registrado!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Código QR interactivo
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: ticketUrl,
                  version: QrVersions.auto,
                  size: 150.0,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                ticketCode,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),

              // Caja de Placa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: Column(
                  children: [
                    const Text('PLACA DE VEHÍCULO', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      plate,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tipo:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(vehicleType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hora Ingreso:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(entryTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tarifa:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text('Bs. ${ratePerHour.toStringAsFixed(2)} / hora', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 12),

              // Botón de Enlace Web
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ticketUrl));
                  AppAlert.success(
                    context,
                    'Enlace del ticket copiado al portapapeles:\n$ticketUrl',
                    title: '¡Copiado!',
                    autoClose: const Duration(milliseconds: 2000),
                  );
                },
                icon: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Copiar Enlace Web del Ticket', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await PdfTicketService.printEntryTicket(
                ticketCode: ticketCode,
                licensePlate: plate,
                vehicleType: vehicleType,
                entryTime: entryTime,
                ratePerHour: ratePerHour,
                cashier: cashier,
                ticketUrl: ticketUrl,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Imprimir / PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanPlateWithCamera() async {
    final plate = await ScannerService().scanLicensePlate(context);
    if (plate != null && plate.isNotEmpty) {
      setState(() {
        _plateController.text = plate;
        _errorMessage = null;
      });
      if (mounted) {
        AppAlert.success(
          context,
          'Placa detectada con IA: $plate',
          title: '¡Placa Detectada!',
          autoClose: const Duration(milliseconds: 1800),
        );
      }
    }
  }

  Future<void> _takeEvidencePhoto() async {
    try {
      final picker = ImagePicker();
      final option = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 14),
              const Text('Foto de Evidencia del Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Tomar Foto con Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capturar estado o rayones del vehículo ahora'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.teal),
                ),
                title: const Text('Seleccionar de la Galería', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (option != null) {
        final XFile? picked = await picker.pickImage(
          source: option,
          imageQuality: 80,
          maxWidth: 1280,
        );
        if (picked != null) {
          setState(() {
            _evidencePhoto = File(picked.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppAlert.error(context, 'No se pudo acceder a la cámara: $e', title: 'Error de Cámara');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Entrada de Vehículo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Selector de Pestañas (Motocicleta, Automóvil, Otro)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: List.generate(_vehicleTypes.length, (index) {
                    final isSelected = _selectedTypeIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTypeIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _vehicleTypes[index]['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _vehicleTypes[index]['name'] == 'Camioneta / Otro' ? 'Otro' : _vehicleTypes[index]['name'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

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
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ),

              // 2. Campo Placa de Vehículo con Escáner
              const Text('Número de Placa *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                decoration: InputDecoration(
                  hintText: 'Ej. B 1234 KLM',
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 22),
                      tooltip: 'Escanear Placa con Cámara (OCR)',
                      onPressed: _scanPlateWithCamera,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // 3. Hora de Entrada (Automática)
              const Text('Fecha y Hora de Ingreso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd MMM yyyy').format(_entryDateTime),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(_entryDateTime),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Foto Opcional de Evidencia
              const Text('Foto del Vehículo (Evidencia Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              if (_evidencePhoto != null)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.file(
                          _evidencePhoto!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Foto de evidencia adjuntada', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                            ),
                            TextButton.icon(
                              onPressed: _takeEvidencePhoto,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Cambiar', style: TextStyle(fontSize: 12)),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _evidencePhoto = null),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                              tooltip: 'Eliminar foto',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: _takeEvidencePhoto,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tomar Foto de Evidencia',
                          style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 18),

              // 5. Notas Opcionales
              const Text('Notas (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ej. Casco incluido, rayón lateral preexistente...',
                ),
              ),
              const SizedBox(height: 32),

              // 6. Botón Guardar Entrada
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSaveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Guardar Entrada e Imprimir Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
