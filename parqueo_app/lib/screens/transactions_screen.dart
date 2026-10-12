import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _selectedPeriod = 'today'; // today, week, month
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    final result = await ApiService().getTransactions(
      period: _selectedPeriod,
      search: _searchController.text.trim(),
    );

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _transactions = result['data']['data'] as List? ?? [];
        _isLoading = false;
      });
    } else {
      // Respaldo de demostración
      setState(() {
        _transactions = [
          {'id': 1, 'entry': {'license_plate': 'B 1234 KLM', 'vehicle_type': {'name': 'Motocicleta'}}, 'exit_time': '12:16', 'total_paid': 5.00},
          {'id': 2, 'entry': {'license_plate': 'B 5678 DEF', 'vehicle_type': {'name': 'Automóvil'}}, 'exit_time': '12:05', 'total_paid': 10.00},
          {'id': 3, 'entry': {'license_plate': 'B 9012 GHI', 'vehicle_type': {'name': 'Motocicleta'}}, 'exit_time': '11:58', 'total_paid': 5.00},
          {'id': 4, 'entry': {'license_plate': 'B 3456 JKL', 'vehicle_type': {'name': 'Automóvil'}}, 'exit_time': '11:42', 'total_paid': 10.00},
          {'id': 5, 'entry': {'license_plate': 'B 7890 MNO', 'vehicle_type': {'name': 'Motocicleta'}}, 'exit_time': '11:35', 'total_paid': 5.00},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transacciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Buscador (Mockup 7)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar transacción...',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                ),
                onSubmitted: (_) => _fetchTransactions(),
              ),
            ),

            // 2. Filtros de Periodo: [Hoy] [Esta Semana] [Este Mes]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  _PeriodTab(
                    label: 'Hoy',
                    isSelected: _selectedPeriod == 'today',
                    onTap: () {
                      setState(() => _selectedPeriod = 'today');
                      _fetchTransactions();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodTab(
                    label: 'Esta Semana',
                    isSelected: _selectedPeriod == 'week',
                    onTap: () {
                      setState(() => _selectedPeriod = 'week');
                      _fetchTransactions();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodTab(
                    label: 'Este Mes',
                    isSelected: _selectedPeriod == 'month',
                    onTap: () {
                      setState(() => _selectedPeriod = 'month');
                      _fetchTransactions();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Encabezado con Fecha y Conteo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${_transactions.length} Transacciones',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // 4. Lista de Transacciones
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactions.isEmpty
                      ? const Center(child: Text('No hay transacciones registradas.', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20.0),
                          itemCount: _transactions.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final t = _transactions[index];
                            final plate = t['entry']?['license_plate'] ?? 'B 1234 KLM';
                            final typeName = t['entry']?['vehicle_type']?['name'] ?? 'Vehículo';
                            final exitTime = t['exit_time']?.toString().split(' ').last ?? '12:00';
                            final amount = t['total_paid'] ?? 0.0;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      typeName.toString().contains('Moto')
                                          ? Icons.two_wheeler_rounded
                                          : Icons.directions_car_rounded,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plate,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          typeName,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        exitTime.length >= 5 ? exitTime.substring(0, 5) : exitTime,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$$amount',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.success,
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

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
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
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
