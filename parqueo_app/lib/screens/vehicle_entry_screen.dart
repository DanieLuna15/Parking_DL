import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/services/scanner_service.dart';

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

  final List<Map<String, dynamic>> _vehicleTypes = [
    {'id': 1, 'name': 'Motocicleta', 'icon': Icons.two_wheeler_rounded, 'rate': 3.0},
    {'id': 2, 'name': 'Automóvil', 'icon': Icons.directions_car_rounded, 'rate': 5.0},
    {'id': 3, 'name': 'Camioneta / Otro', 'icon': Icons.local_shipping_rounded, 'rate': 7.0},
  ];

  Future<void> _handleSaveEntry() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa o escanea la placa del vehículo.');
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
    }
  }

  void _showSuccessDialog(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 10),
            Text('¡Entrada Exitosa!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket: ${ticket['ticket_code'] ?? 'TKT-001'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 6),
            Text('Placa: ${ticket['license_plate']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Tipo: ${ticket['vehicle_type']}', style: const TextStyle(fontSize: 14)),
            Text('Hora: ${ticket['entry_time']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.print_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Ticket listo para imprimir por Bluetooth', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Imprimiendo ticket térmico...'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Imprimir'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 44),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Placa detectada con IA: $plate'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
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

              // 4. Foto Opcional (Mockup 4)
              const Text('Foto del Vehículo (Opcional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cámara activada: Foto capturada con éxito.')),
                  );
                },
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
                        decoration: BoxDecoration(
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
