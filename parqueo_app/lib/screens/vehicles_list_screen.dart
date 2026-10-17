import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/services/pdf_ticket_service.dart';
import '../core/services/scanner_service.dart';
import '../core/widgets/app_alert.dart';
import 'vehicle_exit_screen.dart';

class VehiclesListScreen extends StatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'inside'; // 'all', 'inside', 'exited'
  bool _isLoading = true;
  List<dynamic> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    final result = await ApiService().getVehicles(
      status: _selectedFilter,
      search: _searchController.text.trim(),
    );

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _vehicles = result['data']['data'] as List? ?? [];
        _isLoading = false;
      });
    } else {
      // Datos mock de respaldo si la API no está en línea
      setState(() {
        _vehicles = [
          {'id': 1, 'ticket_code': 'TKT-001', 'license_plate': 'B 1234 KLM', 'status': 'inside', 'duration_formatted': '2h 35m', 'entry_time': '2026-10-17 09:41:00', 'vehicle_type': {'name': 'Motocicleta', 'icon': 'motorcycle', 'rate_per_hour': 5.0}},
          {'id': 2, 'ticket_code': 'TKT-002', 'license_plate': 'B 5678 DEF', 'status': 'inside', 'duration_formatted': '2h 04m', 'entry_time': '2026-10-17 10:12:00', 'vehicle_type': {'name': 'Automóvil', 'icon': 'car', 'rate_per_hour': 10.0}},
          {'id': 3, 'ticket_code': 'TKT-003', 'license_plate': 'B 9012 GHI', 'status': 'inside', 'duration_formatted': '1h 48m', 'entry_time': '2026-10-17 10:28:00', 'vehicle_type': {'name': 'Motocicleta', 'icon': 'motorcycle', 'rate_per_hour': 5.0}},
          {'id': 4, 'ticket_code': 'TKT-004', 'license_plate': 'B 3456 JKL', 'status': 'inside', 'duration_formatted': '1h 11m', 'entry_time': '2026-10-17 11:05:00', 'vehicle_type': {'name': 'Automóvil', 'icon': 'car', 'rate_per_hour': 10.0}},
          {'id': 5, 'ticket_code': 'TKT-005', 'license_plate': 'B 7890 MNO', 'status': 'inside', 'duration_formatted': '56m', 'entry_time': '2026-10-17 11:20:00', 'vehicle_type': {'name': 'Motocicleta', 'icon': 'motorcycle', 'rate_per_hour': 5.0}},
        ];
        _isLoading = false;
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

  Future<void> _scanPlateForSearch() async {
    final plate = await ScannerService().scanLicensePlate(context);
    if (plate != null && plate.isNotEmpty) {
      setState(() {
        _searchController.text = plate;
      });
      _fetchVehicles();
    }
  }

  void _showTicketDetailModal(Map<String, dynamic> v) {
    final ticketCode = v['ticket_code'] ?? 'TKT-PENDIENTE';
    final plate = v['license_plate'] ?? '';
    final typeName = v['vehicle_type']?['name'] ?? 'Vehículo';
    final isInside = v['status'] == 'inside';
    final entryTime = v['entry_time']?.toString() ?? '';
    final duration = v['duration_formatted'] ?? '0m';
    final ratePerHour = (v['vehicle_type']?['rate_per_hour'] ?? 5.0).toDouble();
    final ticketUrl = v['ticket_url'] ?? '${ApiService().baseUrl.replaceAll('/api/v1', '')}/tickets/$ticketCode';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isInside ? AppColors.primarySoft : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isInside ? Icons.confirmation_number_rounded : Icons.receipt_long_rounded,
                          color: isInside ? AppColors.primary : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isInside ? 'Ticket Activo de Parqueo' : 'Historial de Salida',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text('Código: $ticketCode', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isInside ? AppColors.successSoft : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isInside ? 'Adentro' : 'Salió',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isInside ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Código QR interactivo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: QrImageView(
                  data: ticketUrl,
                  version: QrVersions.auto,
                  size: 130.0,
                ),
              ),
              const SizedBox(height: 14),

              // Placa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isInside ? AppColors.primarySoft : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isInside ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    const Text('PLACA REGISTRADA', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      plate,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Detalles
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tipo de Vehículo:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(typeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Hora de Ingreso:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(entryTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tiempo en Parqueo:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(duration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                ],
              ),
              const Divider(height: 24),

              // Botones de Acción
              if (isInside) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VehicleExitScreen(initialPlate: plate)),
                      ).then((_) => _fetchVehicles());
                    },
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Cobrar Salida de Vehículo', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await PdfTicketService.printEntryTicket(
                            ticketCode: ticketCode,
                            licensePlate: plate,
                            vehicleType: typeName,
                            entryTime: entryTime,
                            ratePerHour: ratePerHour,
                            ticketUrl: ticketUrl,
                          );
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: AppColors.primary),
                        label: const Text('Imprimir Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: ticketUrl));
                          AppAlert.success(
                            context,
                            'Enlace copiado al portapapeles:\n$ticketUrl',
                            title: '¡Copiado!',
                            autoClose: const Duration(milliseconds: 2000),
                          );
                        },
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Copiar Enlace', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final exitData = v['exit'];
                      await PdfTicketService.printExitReceipt(
                        ticketCode: ticketCode,
                        licensePlate: plate,
                        vehicleType: typeName,
                        entryTime: entryTime,
                        exitTime: exitData?['exit_time']?.toString() ?? 'Completado',
                        duration: duration,
                        totalPaid: (exitData?['total_paid'] ?? 0.0).toDouble(),
                        paymentMethod: exitData?['payment_method'] ?? 'cash',
                        ticketUrl: ticketUrl,
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: const Text('Reimprimir Recibo (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
        title: const Text('Vehículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchVehicles,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Buscador con icono de filtro (Mockup 6)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar número de placa...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchVehicles();
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 20),
                              tooltip: 'Escanear Placa con Cámara (OCR)',
                              onPressed: _scanPlateForSearch,
                            ),
                          ],
                        ),
                      ),
                      onChanged: (val) {
                        _fetchVehicles();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // 2. Filtros tipo Pastilla: [Todos] [Adentro (18)] [Salieron]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  _FilterChipTab(
                    label: 'Todos',
                    count: 24,
                    isSelected: _selectedFilter == 'all',
                    onTap: () {
                      setState(() => _selectedFilter = 'all');
                      _fetchVehicles();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChipTab(
                    label: 'Adentro',
                    count: 18,
                    isSelected: _selectedFilter == 'inside',
                    onTap: () {
                      setState(() => _selectedFilter = 'inside');
                      _fetchVehicles();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChipTab(
                    label: 'Salieron',
                    count: 6,
                    isSelected: _selectedFilter == 'exited',
                    onTap: () {
                      setState(() => _selectedFilter = 'exited');
                      _fetchVehicles();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Lista de Tarjetas
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _vehicles.isEmpty
                      ? const Center(child: Text('No se encontraron vehículos.', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20.0),
                          itemCount: _vehicles.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final v = _vehicles[index];
                            final plate = v['license_plate'] ?? '';
                            final typeName = v['vehicle_type']?['name'] ?? 'Vehículo';
                            final isInside = v['status'] == 'inside';
                            final duration = v['duration_formatted'] ?? '0m';
                            final time = v['entry_time']?.toString().split(' ').last ?? '10:00';

                            final ticketCode = v['ticket_code'] ?? '';

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showTicketDetailModal(v),
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppColors.cardBorder),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isInside ? AppColors.primarySoft : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          _getVehicleIcon(v['vehicle_type'] ?? typeName),
                                          color: isInside ? AppColors.primary : AppColors.textSecondary,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              plate,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              typeName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            if (ticketCode.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                ticketCode,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            time.length >= 5 ? time.substring(0, 5) : time,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            duration,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isInside ? AppColors.successSoft : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isInside ? 'Adentro' : 'Salió',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: isInside ? AppColors.success : AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipTab({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
