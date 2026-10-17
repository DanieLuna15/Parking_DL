import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/widgets/app_alert.dart';

class VehicleTypesRatesScreen extends StatefulWidget {
  const VehicleTypesRatesScreen({super.key});

  @override
  State<VehicleTypesRatesScreen> createState() => _VehicleTypesRatesScreenState();
}

class _VehicleTypesRatesScreenState extends State<VehicleTypesRatesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _vehicleTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicleTypes();
  }

  Future<void> _fetchVehicleTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService().getVehicleTypes(all: true);

    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _vehicleTypes = res['data'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'No se pudieron cargar las tarifas.';
        _isLoading = false;
      });
    }
  }

  IconData _getIconData(String? iconName, String? typeName) {
    final icon = (iconName ?? '').toLowerCase();
    final name = (typeName ?? '').toLowerCase();

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

  void _showEditTypeModal({Map<String, dynamic>? existingType}) {
    final isEditing = existingType != null;
    final nameController = TextEditingController(text: existingType?['name'] ?? '');
    final rateHourController = TextEditingController(
      text: existingType != null ? existingType['rate_per_hour']?.toString() ?? '5.00' : '5.00',
    );
    final rateFractionController = TextEditingController(
      text: existingType != null ? existingType['rate_per_fraction']?.toString() ?? '1.50' : '1.50',
    );
    final fractionMinsController = TextEditingController(
      text: existingType != null ? existingType['fraction_minutes']?.toString() ?? '15' : '15',
    );
    final graceMinsController = TextEditingController(
      text: existingType != null ? existingType['grace_period_minutes']?.toString() ?? '15' : '15',
    );
    final flatDayController = TextEditingController(
      text: existingType != null ? existingType['flat_day_rate']?.toString() ?? '' : '',
    );

    String selectedIcon = existingType?['icon'] ?? 'car';
    bool isActive = existingType?['is_active'] ?? true;
    bool isSaving = false;

    final availableIcons = [
      {'key': 'car', 'name': 'Automóvil', 'icon': Icons.directions_car_rounded},
      {'key': 'motorcycle', 'name': 'Motocicleta', 'icon': Icons.two_wheeler_rounded},
      {'key': 'truck', 'name': 'Camioneta / Pesado', 'icon': Icons.local_shipping_rounded},
      {'key': 'van', 'name': 'Van / Furgón', 'icon': Icons.airport_shuttle_rounded},
      {'key': 'bus', 'name': 'Bus / Micro', 'icon': Icons.directions_bus_rounded},
      {'key': 'bicycle', 'name': 'Bicicleta', 'icon': Icons.pedal_bike_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header modal
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isEditing ? Icons.price_change_rounded : Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Editar Tarifas' : 'Nuevo Tipo de Vehículo',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                          ),
                          Text(
                            isEditing
                                ? 'Modifica los precios para ${existingType['name']}'
                                : 'Registra una nueva categoría con sus precios',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),

                // 1. Nombre de categoría
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la Categoría *',
                    hintText: 'Ej. Automóvil, Moto, Camión',
                    prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Selector de Ícono
                const Text('Selecciona el Ícono Representativo:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableIcons.map((i) {
                      final isSelected = selectedIcon == i['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            i['icon'] as IconData,
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 18,
                          ),
                          label: Text(i['name'] as String),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedIcon = i['key'] as String);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Precios y Tarifas (Grid de 2 columnas)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rateHourController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Precio por Hora *',
                          prefixText: 'Bs. ',
                          prefixIcon: const Icon(Icons.access_time_filled_rounded, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rateFractionController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Precio Fracción *',
                          prefixText: 'Bs. ',
                          prefixIcon: const Icon(Icons.timelapse_rounded, color: AppColors.secondary),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fractionMinsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Minutos Fracción',
                          suffixText: 'min',
                          prefixIcon: const Icon(Icons.hourglass_bottom_rounded, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: graceMinsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Tolerancia Gratis',
                          suffixText: 'min',
                          prefixIcon: const Icon(Icons.card_giftcard_rounded, color: AppColors.success),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: flatDayController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Tarifa Plana por Día Completo (Opcional)',
                    prefixText: 'Bs. ',
                    hintText: 'Ej. 25.00 para estancias >12h',
                    prefixIcon: const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),

                // Switch Activo
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Categoría Habilitada', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Permitir seleccionar este vehículo al ingresar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setModalState(() => isActive = val),
                ),
                const SizedBox(height: 20),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final rateHour = double.tryParse(rateHourController.text.trim());
                            final rateFraction = double.tryParse(rateFractionController.text.trim()) ?? 0.0;
                            final fractionMins = int.tryParse(fractionMinsController.text.trim()) ?? 15;
                            final graceMins = int.tryParse(graceMinsController.text.trim()) ?? 15;
                            final flatDay = double.tryParse(flatDayController.text.trim());

                            if (name.isEmpty) {
                              AppAlert.warning(modalCtx, 'Por favor ingresa un nombre para la categoría.', title: 'Nombre Requerido');
                              return;
                            }

                            if (rateHour == null || rateHour < 0) {
                              AppAlert.warning(modalCtx, 'Ingresa una tarifa por hora válida.', title: 'Tarifa Inválida');
                              return;
                            }

                            setModalState(() => isSaving = true);

                            final payload = {
                              'name': name,
                              'icon': selectedIcon,
                              'rate_per_hour': rateHour,
                              'rate_per_fraction': rateFraction,
                              'fraction_minutes': fractionMins,
                              'grace_period_minutes': graceMins,
                              'flat_day_rate': flatDay,
                              'is_active': isActive,
                            };

                            Map<String, dynamic> res;
                            if (isEditing) {
                              res = await ApiService().updateVehicleType(existingType['id'] as int, payload);
                            } else {
                              res = await ApiService().createVehicleType(payload);
                            }

                            setModalState(() => isSaving = false);

                            if (!modalCtx.mounted) return;

                            if (res['success'] == true) {
                              Navigator.pop(modalCtx);
                              if (!mounted) return;
                              AppAlert.success(
                                context,
                                isEditing
                                    ? 'Tarifas de "$name" actualizadas correctamente.'
                                    : 'Categoría "$name" agregada con éxito.',
                                title: isEditing ? 'Tarifas Actualizadas' : 'Categoría Creada',
                              );
                              _fetchVehicleTypes();
                            } else {
                              AppAlert.error(
                                modalCtx,
                                res['message'] ?? 'Ocurrió un error al guardar las tarifas.',
                                title: 'Error al Guardar',
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                isEditing ? 'Guardar Cambios de Tarifa' : 'Crear Tipo de Vehículo',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteType(Map<String, dynamic> type) async {
    final confirmed = await AppAlert.confirm(
      context,
      title: '¿Eliminar Categoría?',
      message: '¿Estás seguro de que deseas eliminar "${type['name']}"? Si tiene registros asociados se recomienda desactivarlo.',
      confirmText: 'Sí, Eliminar',
      cancelText: 'Cancelar',
      destructive: true,
    );

    if (!confirmed) return;

    final res = await ApiService().deleteVehicleType(type['id'] as int);

    if (!mounted) return;

    if (res['success'] == true) {
      AppAlert.success(context, 'Categoría eliminada correctamente.', title: 'Eliminado');
      _fetchVehicleTypes();
    } else {
      AppAlert.error(context, res['message'] ?? 'No se pudo eliminar la categoría.', title: 'No Eliminado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tarifas por Tipo de Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar lista',
            onPressed: _fetchVehicleTypes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Tipo', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showEditTypeModal(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Cargando tarifas y tipos de vehículo...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchVehicleTypes,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_vehicleTypes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_outlined, size: 72, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No hay categorías de vehículos registradas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Toca el botón "+ Nuevo Tipo" para crear tu primera tarifa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showEditTypeModal(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crear Primera Tarifa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVehicleTypes,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          // Banner informativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarifas por Categoría',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Los precios configurados aquí se aplicarán automáticamente al registrar entradas y calcular los cobros de salida.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de tarjetas
          ..._vehicleTypes.map((type) {
            final name = type['name'] ?? 'Vehículo';
            final iconName = type['icon']?.toString();
            final rateHour = double.tryParse(type['rate_per_hour'].toString()) ?? 0.0;
            final rateFraction = double.tryParse(type['rate_per_fraction']?.toString() ?? '0.0') ?? 0.0;
            final fractionMinutes = type['fraction_minutes'] ?? 15;
            final gracePeriod = type['grace_period_minutes'] ?? 15;
            final flatDayRate = type['flat_day_rate'] != null ? double.tryParse(type['flat_day_rate'].toString()) : null;
            final isActive = type['is_active'] == true || type['is_active'] == 1;

            final iconData = _getIconData(iconName, name);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.cardBorder : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Encabezado de la tarjeta
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primarySoft : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            iconData,
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppColors.successSoft : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isActive ? 'Activo' : 'Inactivo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? AppColors.success : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tolerancia de cortesía: $gracePeriod min gratis',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onSelected: (val) {
                            if (val == 'edit') {
                              _showEditTypeModal(existingType: type as Map<String, dynamic>);
                            } else if (val == 'delete') {
                              _handleDeleteType(type as Map<String, dynamic>);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  SizedBox(width: 10),
                                  Text('Editar Tarifas'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                  SizedBox(width: 10),
                                  Text('Eliminar', style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Resumen de precios
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Precio hora
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Por Hora', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  'Bs. ${rateHour.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Precio fracción
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Frac. (${fractionMinutes}m)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  'Bs. ${rateFraction.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Tarifa plana día (si existe)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tarifa Día', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  flatDayRate != null ? 'Bs. ${flatDayRate.toStringAsFixed(2)}' : 'No fijada',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: flatDayRate != null ? Colors.orange.shade800 : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón directo para editar tarifa
                  InkWell(
                    onTap: () => _showEditTypeModal(existingType: type as Map<String, dynamic>),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Modificar Precios de Esta Categoría',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
