import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  int _totalVehicles = 24;
  double _totalRevenue = 180.0;
  int _motorcyclesCount = 16;
  int _carsCount = 8;
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final result = await ApiService().getDailyReport(date: dateStr);

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      setState(() {
        _totalVehicles = data['total_vehicles'] ?? 24;
        _totalRevenue = (data['total_revenue'] as num?)?.toDouble() ?? 180.0;
        final breakdown = data['type_breakdown'] as List? ?? [];
        for (var b in breakdown) {
          final icon = b['icon']?.toString().toLowerCase();
          if (icon == 'motorcycle') {
            _motorcyclesCount = b['count'] ?? 16;
          } else if (icon == 'car') {
            _carsCount = b['count'] ?? 8;
          }
        }
        _chartData = List<Map<String, dynamic>>.from(data['chart_data'] ?? []);
        _isLoading = false;
      });
    } else {
      // Mockup por defecto para visualización inmediata
      setState(() {
        _totalVehicles = 24;
        _totalRevenue = 180.0;
        _motorcyclesCount = 16;
        _carsCount = 8;
        _chartData = [
          {'hour': '08:00', 'revenue': 10.0},
          {'hour': '10:00', 'revenue': 25.0},
          {'hour': '12:00', 'revenue': 18.0},
          {'hour': '14:00', 'revenue': 30.0},
          {'hour': '16:00', 'revenue': 22.0},
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
        title: const Text('Reportes'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Selector de fecha (Mockup 8)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Row(
                      children: [
                        Text('Hoy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. Tarjetas de Métricas: Total Vehículos e Ingresos (Mockup 8)
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Vehículos',
                      value: '$_totalVehicles',
                      percentage: '↑ 20%',
                      icon: Icons.directions_car_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primarySoft,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      title: 'Total Ingresos',
                      value: '\$$_totalRevenue',
                      percentage: '↑ 15%',
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFE0F2FE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Desglose por Tipos de Vehículo
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Motocicletas', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('$_motorcyclesCount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            const Text('67%', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 28),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Automóviles', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('$_carsCount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            const Text('33%', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 28),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Barra de progreso combinada
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Row(
                        children: [
                          Expanded(flex: 67, child: Container(height: 8, color: AppColors.primary)),
                          Expanded(flex: 33, child: Container(height: 8, color: Colors.blue.shade200)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. Gráfico de Ingresos (Revenue Chart - Mockup 8)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Gráfico de Ingresos',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Text('Hoy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 40,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  const hours = ['08:00', '10:00', '12:00', '14:00', '16:00'];
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < hours.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(hours[idx], style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: _chartData.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final rev = (entry.value['revenue'] as num?)?.toDouble() ?? 10.0;
                            return _buildBar(idx, rev);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.primary.withOpacity(0.85),
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String percentage;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.percentage,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(percentage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
        ],
      ),
    );
  }
}
