import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/services/pdf_ticket_service.dart';
import '../core/services/scanner_service.dart';
import '../core/widgets/app_alert.dart';
import 'payment_methods_screen.dart';

class VehicleExitScreen extends StatefulWidget {
  final String? initialPlate;

  const VehicleExitScreen({super.key, this.initialPlate});

  @override
  State<VehicleExitScreen> createState() => _VehicleExitScreenState();
}

class _VehicleExitScreenState extends State<VehicleExitScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _referenceController = TextEditingController();

  bool _isSearching = false;
  bool _isCompleting = false;
  String? _errorMessage;

  Map<String, dynamic>? _exitData;
  String _paymentMethod = 'cash'; // cash, e_wallet, card, transfer
  int? _selectedPaymentMethodId;
  List<dynamic> _availablePaymentMethods = [];
  double _discountAmount = 0.0;
  bool _isLostTicket = false;
  double _lostTicketPenalty = 20.0;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    if (widget.initialPlate != null && widget.initialPlate!.isNotEmpty) {
      _searchController.text = widget.initialPlate!;
      _calculateExit(widget.initialPlate!);
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final res = await ApiService().getPaymentMethods();
      if (res['success'] == true && res['data'] != null) {
        final list = res['data'] as List<dynamic>;
        if (list.isNotEmpty && mounted) {
          setState(() {
            _availablePaymentMethods = list;
            final defaultMethod = _availablePaymentMethods.firstWhere(
              (m) => m['code'] == 'cash',
              orElse: () => _availablePaymentMethods.first,
            );
            _selectedPaymentMethodId = defaultMethod['id'];
            _paymentMethod = defaultMethod['code'] ?? 'cash';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _calculateExit(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    final result = await ApiService().calculateExit(query.trim());

    setState(() {
      _isSearching = false;
    });

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _exitData = result['data'];
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Vehículo no encontrado adentro';
        _exitData = null;
      });
    }
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

  Future<void> _completeExit() async {
    if (_exitData == null) return;

    // Verificar si el método exige referencia obligatoria
    final selectedMethod = _availablePaymentMethods.firstWhere(
      (m) => m['id'] == _selectedPaymentMethodId,
      orElse: () => null,
    );

    if (selectedMethod != null && selectedMethod['requires_reference'] == true) {
      if (_referenceController.text.trim().isEmpty) {
        AppAlert.warning(
          context,
          'El método "${selectedMethod['name']}" requiere número de comprobante o referencia.',
          title: 'Referencia Requerida',
        );
        return;
      }
    }

    setState(() {
      _isCompleting = true;
    });

    final result = await ApiService().completeExit(
      entryId: _exitData!['entry_id'],
      paymentMethod: _paymentMethod,
      paymentMethodId: _selectedPaymentMethodId,
      referenceNumber: _referenceController.text.trim().isNotEmpty ? _referenceController.text.trim() : null,
      discount: _discountAmount,
      penalty: _isLostTicket ? _lostTicketPenalty : 0.0,
      isLostTicket: _isLostTicket,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    setState(() {
      _isCompleting = false;
    });

    if (!mounted) return;
    if (result['success'] == true) {
      _showExitSuccessDialog(result['data']);
    } else {
      AppAlert.error(context, result['message'] ?? 'Error al procesar cobro');
    }
  }

  Future<void> _scanTicketOrPlate() async {
    final option = await showModalBottomSheet<String>(
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
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('Escanear para Salida', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
                ),
                title: const Text('Escanear QR / Código de Ticket', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Leer ticket físico con cámara o código de barras'),
                onTap: () => Navigator.pop(ctx, 'ticket'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.document_scanner_rounded, color: Colors.teal),
                ),
                title: const Text('Escanear Placa del Vehículo (OCR)', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Reconocer placa con IA'),
                onTap: () => Navigator.pop(ctx, 'plate'),
              ),
            ],
          ),
        ),
      ),
    );

    if (option == 'ticket' && mounted) {
      final code = await ScannerService().scanTicketCode(context);
      if (code != null && code.isNotEmpty) {
        setState(() {
          _searchController.text = code;
        });
        _calculateExit(code);
      }
    } else if (option == 'plate' && mounted) {
      final plate = await ScannerService().scanLicensePlate(context);
      if (plate != null && plate.isNotEmpty) {
        setState(() {
          _searchController.text = plate;
        });
        _calculateExit(plate);
      }
    }
  }

  void _showExitSuccessDialog(Map<String, dynamic> data) {
    final ticketCode = data['ticket_code'] ?? 'TKT-001';
    final plate = data['license_plate'] ?? _searchController.text.trim();
    final vehicleType = data['vehicle_type'] ?? 'Vehículo';
    final entryTime = data['entry_time'] ?? '';
    final exitTime = data['exit_time'] ?? '';
    final duration = data['duration_formatted'] ?? '';
    final totalPaid = (data['total_paid'] ?? 0.0).toDouble();
    final discount = (data['discount'] ?? 0.0).toDouble();
    final penaltyAmount = (data['penalty_amount'] ?? 0.0).toDouble();
    final isLostTicket = data['is_lost_ticket'] == true || penaltyAmount > 0;
    final paymentMethod = data['payment_method'] ?? _paymentMethod;
    final cashier = data['cashier'] ?? 'Daniel Luna';
    final ticketUrl = data['ticket_url'] ?? '${ApiService().baseUrl.replaceAll('/api/v1', '')}/tickets/$ticketCode';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              isLostTicket ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isLostTicket ? AppColors.warning : AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              isLostTicket ? '¡Cobro de Ticket Perdido!' : '¡Cobro Completado!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLostTicket)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.report_problem_rounded, color: AppColors.error, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'BOLETO EXTRAVIADO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.error),
                      ),
                    ],
                  ),
                ),

              // Código QR de verificación del comprobante
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
                  size: 140.0,
                ),
              ),
              const SizedBox(height: 12),

              // Caja de Placa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isLostTicket ? const Color(0xFFFEF2F2) : AppColors.successSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isLostTicket ? const Color(0xFFFCA5A5) : AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isLostTicket ? 'VEHÍCULO (EXTRAVÍO)' : 'PLACA COBRADA',
                      style: TextStyle(
                        fontSize: 10,
                        color: isLostTicket ? AppColors.error : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plate,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: isLostTicket ? AppColors.error : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Info del vehículo y tipo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tipo:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getVehicleIcon(vehicleType), size: 16, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(vehicleType.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ticket:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(ticketCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Permanencia:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(duration, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              if (penaltyAmount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recargo Extravío:', style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.bold)),
                    Text(
                      '+ ${data['currency'] ?? 'Bs. '}${penaltyAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Método de Pago:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(paymentMethod.toString().toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 18),

              // Monto Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL COBRADO:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    '${data['currency'] ?? 'Bs. '}${totalPaid.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Botón de Enlace Web
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: ticketUrl));
                  AppAlert.success(
                    context,
                    'Enlace copiado al portapapeles:\n$ticketUrl',
                    title: '¡Copiado!',
                    autoClose: const Duration(milliseconds: 2000),
                  );
                },
                icon: const Icon(Icons.link_rounded, size: 16),
                label: const Text('Copiar Enlace Web del Recibo', style: TextStyle(fontSize: 12)),
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
              await PdfTicketService.printExitReceipt(
                ticketCode: ticketCode,
                licensePlate: plate,
                vehicleType: vehicleType,
                entryTime: entryTime,
                exitTime: exitTime,
                duration: duration,
                totalPaid: totalPaid,
                paymentMethod: paymentMethod,
                discount: discount,
                penaltyAmount: penaltyAmount,
                isLostTicket: isLostTicket,
                cashier: cashier,
                ticketUrl: ticketUrl,
              );
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: const Text('Imprimir / PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDirectLostTicketModal() async {
    final plateCtrl = TextEditingController(text: _searchController.text.trim());
    final feeCtrl = TextEditingController(text: '30.00');
    final notesCtrl = TextEditingController();
    int selectedVehicleTypeId = 2; // Default automóvil
    String lostPaymentMethod = 'cash';
    int? lostPaymentMethodId;
    if (_availablePaymentMethods.isNotEmpty) {
      lostPaymentMethodId = _availablePaymentMethods.first['id'] as int;
      lostPaymentMethod = _availablePaymentMethods.first['code'] ?? 'cash';
    }
    bool isSubmitting = false;

    List<dynamic> vehicleTypes = [
      {'id': 1, 'name': 'Motocicleta'},
      {'id': 2, 'name': 'Automóvil'},
      {'id': 3, 'name': 'Camioneta / SUV'},
    ];

    try {
      final typesRes = await ApiService().getVehicleTypes();
      if (typesRes['success'] == true && typesRes['data'] != null) {
        final list = typesRes['data'] as List;
        if (list.isNotEmpty) {
          vehicleTypes = list;
          selectedVehicleTypeId = vehicleTypes.first['id'] as int;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.report_problem_rounded, color: AppColors.error, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Cobro Directo - Ticket Perdido',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Utiliza este formulario si el conductor extravió su ticket físico y no cuenta con registro de entrada.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // 1. Campo Placa con escáner OCR
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: plateCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Número de Placa',
                            hintText: 'Ej. 4589ABC',
                            prefixIcon: Icon(Icons.pin_rounded, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.document_scanner_rounded, color: Colors.white),
                        tooltip: 'Escanear Placa con Cámara',
                        onPressed: () async {
                          final scanned = await ScannerService().scanLicensePlate(context);
                          if (scanned != null && scanned.isNotEmpty) {
                            setModalState(() {
                              plateCtrl.text = scanned;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Tipo de Vehículo
                  DropdownButtonFormField<int>(
                    value: selectedVehicleTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Vehículo',
                      prefixIcon: Icon(Icons.directions_car_rounded, color: AppColors.primary),
                    ),
                    items: vehicleTypes.map<DropdownMenuItem<int>>((t) {
                      return DropdownMenuItem<int>(
                        value: t['id'] as int,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getVehicleIcon(t), size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(t['name'] ?? 'Vehículo'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedVehicleTypeId = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3. Monto Tarifa Fija por Extravío
                  TextField(
                    controller: feeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto Total a Cobrar por Extravío',
                      prefixText: 'Bs. ',
                      prefixIcon: Icon(Icons.payments_rounded, color: AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. Selector de Método de Pago
                  const Text('Método de Pago:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (_availablePaymentMethods.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availablePaymentMethods.map((m) {
                        final id = m['id'] as int;
                        final name = m['name'] ?? 'Pago';
                        final code = m['code'] ?? 'other';
                        final isSelected = lostPaymentMethodId == id;
                        IconData icon = Icons.payments_outlined;
                        if (code == 'e_wallet') icon = Icons.qr_code_2_rounded;
                        if (code == 'card') icon = Icons.credit_card_rounded;
                        if (code == 'transfer') icon = Icons.account_balance_rounded;

                        return ChoiceChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textPrimary),
                              const SizedBox(width: 4),
                              Text(name, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                            ],
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (_) => setModalState(() {
                            lostPaymentMethodId = id;
                            lostPaymentMethod = code;
                          }),
                        );
                      }).toList(),
                    )
                  else
                    Row(
                      children: [
                        _buildMiniPaymentOption(
                          label: 'Efectivo',
                          icon: Icons.payments_outlined,
                          isSelected: lostPaymentMethod == 'cash',
                          onTap: () => setModalState(() => lostPaymentMethod = 'cash'),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniPaymentOption(
                          label: 'QR',
                          icon: Icons.qr_code_2_rounded,
                          isSelected: lostPaymentMethod == 'e_wallet',
                          onTap: () => setModalState(() => lostPaymentMethod = 'e_wallet'),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniPaymentOption(
                          label: 'Tarjeta',
                          icon: Icons.credit_card_rounded,
                          isSelected: lostPaymentMethod == 'card',
                          onTap: () => setModalState(() => lostPaymentMethod = 'card'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),

                  // 5. Observaciones opcionales
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas / Observación (Opcional)',
                      hintText: 'Ej. Identificación verificada con carnet',
                      prefixIcon: Icon(Icons.note_alt_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Botón de Confirmación
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final plate = plateCtrl.text.trim();
                              if (plate.isEmpty) {
                                AppAlert.warning(context, 'Por favor ingresa la placa del vehículo', title: 'Campo Requerido');
                                return;
                              }
                              final fee = double.tryParse(feeCtrl.text.trim()) ?? 30.0;

                              setModalState(() => isSubmitting = true);

                              final res = await ApiService().completeLostTicket(
                                licensePlate: plate,
                                vehicleTypeId: selectedVehicleTypeId,
                                lostFee: fee,
                                paymentMethod: lostPaymentMethod,
                                paymentMethodId: lostPaymentMethodId,
                                notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                              );

                              setModalState(() => isSubmitting = false);

                              if (!modalContext.mounted) return;
                              if (res['success'] == true && res['data'] != null) {
                                Navigator.pop(modalContext);
                                if (context.mounted) {
                                  _showExitSuccessDialog(res['data']);
                                }
                              } else {
                                AppAlert.error(modalContext, res['message'] ?? 'Error al procesar cobro directo');
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        isSubmitting ? 'Procesando...' : 'Confirmar Cobro de Ticket Perdido',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniPaymentOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Salida de Vehículo'),
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
              // 1. Buscador de Placa / Escáner QR
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Buscar Placa o Ticket...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                          onPressed: () => _calculateExit(_searchController.text),
                        ),
                      ),
                      onSubmitted: _calculateExit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                      tooltip: 'Escanear Ticket QR / Placa',
                      onPressed: _scanTicketOrPlate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isSearching)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.errorSoft, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '¿El conductor extravió su ticket físico?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Puedes cobrar directamente la tarifa fija por ticket perdido y liberar el vehículo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showDirectLostTicketModal,
                          icon: const Icon(Icons.report_problem_rounded, size: 18),
                          label: const Text('🚨 Cobro Directo por Ticket Perdido'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              else if (_exitData == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppColors.primary),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Busca la placa o escanea el ticket',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Usa el buscador superior o el botón de cámara para escanear el código QR o la placa con IA.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      const Divider(),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _showDirectLostTicketModal,
                        icon: const Icon(Icons.report_problem_rounded, color: AppColors.error, size: 18),
                        label: const Text(
                          '🚨 ¿Ticket Extraviado? Cobro Directo',
                          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
              else if (_exitData != null) ...[
                // Cálculos en vivo
                () {
                  final baseFee = (_exitData!['parking_fee'] is num)
                      ? (_exitData!['parking_fee'] as num).toDouble()
                      : (double.tryParse(_exitData!['parking_fee'].toString()) ?? 0.0);
                  final totalToPay = (baseFee + (_isLostTicket ? _lostTicketPenalty : 0.0) - _discountAmount).clamp(0.0, 999999.0);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Tarjeta del Vehículo Encontrado (Mockup 5)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getVehicleIcon(_exitData!['vehicle_type']),
                                color: AppColors.primary,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _exitData!['license_plate'] ?? '',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _exitData!['vehicle_type']?['name'] ?? 'Vehículo',
                                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 3. Tiempos y Duración
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Hora de Entrada:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                Text(_exitData!['entry_time'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Duración:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                Text(
                                  _exitData!['duration_formatted'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Tarjeta de ¿Ticket Extraviado?
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isLostTicket ? const Color(0xFFFEF2F2) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isLostTicket ? const Color(0xFFFCA5A5) : AppColors.cardBorder,
                            width: _isLostTicket ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _isLostTicket ? AppColors.errorSoft : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.report_problem_rounded,
                                        color: _isLostTicket ? AppColors.error : AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('¿Ticket Extraviado?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text(
                                          _isLostTicket ? 'Se aplicará recargo por pérdida' : 'El cliente presentó su ticket',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _isLostTicket,
                                  activeColor: AppColors.error,
                                  onChanged: (val) {
                                    setState(() => _isLostTicket = val);
                                  },
                                ),
                              ],
                            ),
                            if (_isLostTicket) ...[
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recargo Boleto Perdido:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  SizedBox(
                                    width: 120,
                                    height: 42,
                                    child: TextField(
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.end,
                                      controller: TextEditingController(text: _lostTicketPenalty.toStringAsFixed(2)),
                                      decoration: InputDecoration(
                                        prefixText: '${_exitData!['currency'] ?? 'Bs. '} ',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        isDense: true,
                                      ),
                                      onChanged: (val) {
                                        final p = double.tryParse(val);
                                        if (p != null) {
                                          setState(() => _lostTicketPenalty = p);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 5. Selector Dinámico de Método de Pago
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Método de Pago', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                              ).then((_) => _loadPaymentMethods());
                            },
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            child: const Text('Gestionar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_availablePaymentMethods.isNotEmpty)
                        SizedBox(
                          height: 78,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availablePaymentMethods.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (ctx, index) {
                              final m = _availablePaymentMethods[index];
                              final id = m['id'] as int;
                              final code = m['code'] ?? 'other';
                              final name = m['name'] ?? 'Pago';
                              final isSelected = _selectedPaymentMethodId == id || (_selectedPaymentMethodId == null && _paymentMethod == code);

                              IconData icon = Icons.payments_outlined;
                              if (code == 'e_wallet') icon = Icons.qr_code_2_rounded;
                              if (code == 'card') icon = Icons.credit_card_rounded;
                              if (code == 'transfer') icon = Icons.account_balance_rounded;

                              return _PaymentMethodCard(
                                icon: icon,
                                label: name,
                                isSelected: isSelected,
                                isFlexible: false,
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethodId = id;
                                    _paymentMethod = code;
                                  });
                                },
                              );
                            },
                          ),
                        )
                      else
                        Row(
                          children: [
                            _PaymentMethodCard(
                              icon: Icons.payments_outlined,
                              label: 'Efectivo',
                              isSelected: _paymentMethod == 'cash',
                              onTap: () => setState(() => _paymentMethod = 'cash'),
                            ),
                            const SizedBox(width: 10),
                            _PaymentMethodCard(
                              icon: Icons.qr_code_2_rounded,
                              label: 'Pago QR',
                              isSelected: _paymentMethod == 'e_wallet',
                              onTap: () => setState(() => _paymentMethod = 'e_wallet'),
                            ),
                            const SizedBox(width: 10),
                            _PaymentMethodCard(
                              icon: Icons.credit_card_rounded,
                              label: 'Tarjeta',
                              isSelected: _paymentMethod == 'card',
                              onTap: () => setState(() => _paymentMethod = 'card'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Detalle Dinámico según el método de pago seleccionado
                      Builder(
                        builder: (ctx) {
                          final currentMethod = _availablePaymentMethods.firstWhere(
                            (m) => m['id'] == _selectedPaymentMethodId,
                            orElse: () => null,
                          );

                          final isQr = _paymentMethod == 'e_wallet' || (currentMethod != null && currentMethod['qr_image_url'] != null);
                          final isCard = _paymentMethod == 'card';
                          final isTransfer = _paymentMethod == 'transfer';
                          final qrImageUrl = currentMethod?['qr_image_url'] as String?;
                          final bankName = currentMethod?['bank_name'] as String?;
                          final accountNum = currentMethod?['account_number'] as String?;
                          final accountHolder = currentMethod?['account_holder'] as String?;
                          final phoneNum = currentMethod?['phone_number'] as String?;
                          final instructions = currentMethod?['instructions'] as String?;
                          final requiresRef = currentMethod?['requires_reference'] == true || isQr || isTransfer;

                          if (isQr) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.qr_code_scanner_rounded, color: AppColors.success, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentMethod?['name'] ?? 'Cobro con Billetera Móvil / QR',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF166534)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      children: [
                                        if (qrImageUrl != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              qrImageUrl,
                                              height: 180,
                                              width: 180,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2_rounded, size: 120, color: AppColors.textPrimary),
                                            ),
                                          )
                                        else
                                          const Icon(Icons.qr_code_2_rounded, size: 120, color: AppColors.textPrimary),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Monto a pagar: ${_exitData!['currency'] ?? 'Bs. '}${totalToPay.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.success),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    instructions ?? 'Muestra este código al conductor para escanear desde su app bancaria o billetera digital.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                                  ),
                                  if (bankName != null || accountNum != null || accountHolder != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          if (bankName != null) Text('Banco: $bankName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          if (accountNum != null) Text('Cta: $accountNum', style: const TextStyle(fontSize: 12)),
                                          if (accountHolder != null) Text('Titular: $accountHolder', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _referenceController,
                                    decoration: InputDecoration(
                                      labelText: requiresRef ? 'Nro. de Referencia / Comprobante *' : 'Nro. de Referencia (Opcional)',
                                      hintText: 'Ej. REF-892348',
                                      prefixIcon: const Icon(Icons.receipt_outlined, color: AppColors.success),
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (isTransfer) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.account_balance_rounded, color: Color(0xFFD97706), size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        currentMethod?['name'] ?? 'Transferencia Bancaria',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF92400E)),
                                      ),
                                    ],
                                  ),
                                  if (bankName != null || accountNum != null || accountHolder != null || phoneNum != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (bankName != null) Text('Banco: $bankName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          if (accountNum != null) Text('Nro. Cuenta: $accountNum', style: const TextStyle(fontSize: 12)),
                                          if (accountHolder != null) Text('Titular: $accountHolder', style: const TextStyle(fontSize: 12)),
                                          if (phoneNum != null) Text('Móvil: $phoneNum', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (instructions != null && instructions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(instructions, style: const TextStyle(fontSize: 12, color: Color(0xFF78350F))),
                                  ],
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _referenceController,
                                    decoration: InputDecoration(
                                      labelText: requiresRef ? 'Nro. de Referencia / Transacción *' : 'Nro. de Referencia (Opcional)',
                                      hintText: 'Ej. TRX-459021',
                                      prefixIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD97706)),
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (isCard) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.credit_card_rounded, color: AppColors.primary, size: 24),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Pase la tarjeta por el punto de venta (POS) y confirme la transacción.',
                                          style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (requiresRef) ...[
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _referenceController,
                                      decoration: const InputDecoration(
                                        labelText: 'Código de Aprobación POS / Voucher',
                                        hintText: 'Ej. AP-99238',
                                        prefixIcon: Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }

                          // Efectivo u otro
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 20),

                      // Resumen de Cobro Total
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tarifa por Tiempo:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Text(
                                  '${_exitData!['currency'] ?? 'Bs. '}${baseFee.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                            if (_isLostTicket) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Recargo Ticket Perdido:', style: TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.bold)),
                                  Text(
                                    '+ ${_exitData!['currency'] ?? 'Bs. '}${_lostTicketPenalty.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.error),
                                  ),
                                ],
                              ),
                            ],
                            if (_discountAmount > 0) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Descuento:', style: TextStyle(fontSize: 13, color: AppColors.success)),
                                  Text(
                                    '- ${_exitData!['currency'] ?? 'Bs. '}${_discountAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL A COBRAR:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                Text(
                                  '${_exitData!['currency'] ?? 'Bs. '}${totalToPay.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. Botón Completar Salida (Verde)
                      ElevatedButton(
                        onPressed: _isCompleting ? null : _completeExit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isCompleting
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Completar Salida (${_exitData!['currency'] ?? 'Bs. '}${totalToPay.toStringAsFixed(2)})',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFlexible;

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isFlexible = true,
  });

  @override
  Widget build(BuildContext context) {
    final childWidget = GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 95),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );

    if (isFlexible) {
      return Expanded(child: childWidget);
    }
    return childWidget;
  }
}
