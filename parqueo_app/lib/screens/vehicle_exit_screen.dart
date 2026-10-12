import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/services/scanner_service.dart';

class VehicleExitScreen extends StatefulWidget {
  final String? initialPlate;

  const VehicleExitScreen({super.key, this.initialPlate});

  @override
  State<VehicleExitScreen> createState() => _VehicleExitScreenState();
}

class _VehicleExitScreenState extends State<VehicleExitScreen> {
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSearching = false;
  bool _isCompleting = false;
  String? _errorMessage;

  Map<String, dynamic>? _exitData;
  String _paymentMethod = 'cash'; // cash, e_wallet, card
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.initialPlate != null && widget.initialPlate!.isNotEmpty) {
      _searchController.text = widget.initialPlate!;
      _calculateExit(widget.initialPlate!);
    } else {
      // Valor de demostración predeterminado como en el mockup
      _searchController.text = 'B 1234 KLM';
      _calculateExit('B 1234 KLM');
    }
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

  Future<void> _completeExit() async {
    if (_exitData == null) return;

    setState(() {
      _isCompleting = true;
    });

    final result = await ApiService().completeExit(
      entryId: _exitData!['entry_id'],
      paymentMethod: _paymentMethod,
      discount: _discountAmount,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    setState(() {
      _isCompleting = false;
    });

    if (result['success'] == true) {
      if (!mounted) return;
      _showExitSuccessDialog(result['data']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error al procesar cobro'), backgroundColor: AppColors.error),
      );
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('¡Cobro Completado!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Placa: ${data['license_plate']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Permanencia: ${data['duration_formatted']}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              'Total Cobrado: ${data['currency']}${data['total_paid']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.success),
            ),
            Text('Método: ${data['payment_method'].toString().toUpperCase()}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.successSoft, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.print_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Recibo impreso. Barrera de salida abierta.', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Finalizar'),
          ),
        ],
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
              else if (_errorMessage != null)
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
                )
              else if (_exitData != null) ...[
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
                        child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 32),
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
                const SizedBox(height: 20),

                // 4. Tarifa de Parqueo
                const Text('Tarifa de Parqueo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_exitData!['currency'] ?? '\$'}${_exitData!['parking_fee'] ?? '0.00'}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        tooltip: 'Aplicar descuento o ajuste',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Selector de Método de Pago (Mockup 5)
                const Text('Método de Pago', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
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

                // Detalle Dinámico de Billetera Móvil / Pago QR
                if (_paymentMethod == 'e_wallet')
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, color: AppColors.success, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Cobro con Billetera Móvil / QR',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 110, color: AppColors.textPrimary),
                              Text(
                                'Monto a pagar: ${_exitData!['currency'] ?? '\$'}${_exitData!['parking_fee'] ?? '0.00'}',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Muestra este código al conductor para escanear desde su app bancaria o billetera digital.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Referencia / Comprobante',
                            hintText: 'Ej. REF-892348',
                            prefixIcon: Icon(Icons.receipt_outlined, color: AppColors.success),
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_paymentMethod == 'card')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Row(
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
                  ),

                const SizedBox(height: 24),

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
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 22),
                            SizedBox(width: 8),
                            Text('Completar Salida y Cobrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
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

  const _PaymentMethodCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
              const SizedBox(height: 6),
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
}
