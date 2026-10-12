import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/services/scanner_service.dart';

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
          {'id': 1, 'license_plate': 'B 1234 KLM', 'status': 'inside', 'duration_formatted': '2h 35m', 'entry_time': '09:41', 'vehicle_type': {'name': 'Motocicleta', 'icon': 'motorcycle'}},
          {'id': 2, 'license_plate': 'B 5678 DEF', 'status': 'inside', 'duration_formatted': '2h 04m', 'entry_time': '10:12', 'vehicle_type': {'name': 'Automóvil', 'icon': 'car'}},
          {'id': 3, 'license_plate': 'B 9012 GHI', 'status': 'inside', 'duration_formatted': '1h 48m', 'entry_time': '10:28', 'vehicle_type': {'name': 'Motocicleta', 'icon': 'motorcycle'}},
          {'id': 4, 'license_plate': 'B 3456 JKL', 'status': 'inside', 'duration_formatted': '1h 11m', 'entry_time': '11:05', 'vehicle_type': {'name': 'Automóvil', 'icon': 'car'}},
          {'id': 5, 'license_plate': 'B 7890 MNO', 'status': 'inside', 'duration_formatted': '56m', 'entry_time': '11:20', 'vehicle_type': {'name': 'Motocicleta', 'icon': 'motorcycle'}},
        ];
        _isLoading = false;
      });
    }
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

                            return Container(
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
                                      typeName.toString().contains('Moto')
                                          ? Icons.two_wheeler_rounded
                                          : Icons.directions_car_rounded,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          typeName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
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
