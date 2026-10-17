import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/widgets/app_alert.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _paymentMethods = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ApiService().getPaymentMethods(all: true);

    if (!mounted) return;

    if (res['success'] == true && res['data'] != null) {
      setState(() {
        _paymentMethods = res['data'] as List<dynamic>;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'No se pudieron cargar los métodos de pago.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleMethod(int id, bool currentStatus) async {
    // Optimistic UI update
    setState(() {
      final index = _paymentMethods.indexWhere((m) => m['id'] == id);
      if (index != -1) {
        _paymentMethods[index]['is_active'] = !currentStatus;
      }
    });

    final res = await ApiService().togglePaymentMethod(id);
    if (!mounted) return;

    if (res['success'] != true) {
      // Revert if failed
      setState(() {
        final index = _paymentMethods.indexWhere((m) => m['id'] == id);
        if (index != -1) {
          _paymentMethods[index]['is_active'] = currentStatus;
        }
      });
      AppAlert.error(context, res['message'] ?? 'Error al cambiar estado');
    } else {
      AppAlert.success(context, res['message'] ?? 'Estado actualizado', autoClose: const Duration(milliseconds: 1400));
    }
  }

  Future<void> _deleteMethod(int id, String name) async {
    final confirm = await AppAlert.confirm(
      context,
      title: '¿Eliminar "$name"?',
      message: 'Esta acción no se puede deshacer.',
      confirmText: 'Sí, eliminar',
      destructive: true,
    );

    if (!confirm || !mounted) return;

    AppAlert.showLoading(context, 'Eliminando...');
    final res = await ApiService().deletePaymentMethod(id);
    if (!mounted) return;
    AppAlert.hideLoading(context);

    await AppAlert.fromResponse(context, res, successMessage: 'Forma de pago eliminada correctamente');
    if (res['success'] == true) _loadPaymentMethods();
  }

  Future<void> _pickAndUploadQr(int id, String name) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Subir Código QR para $name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Tomar foto con la cámara'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDF4),
                  child: Icon(Icons.photo_library_rounded, color: AppColors.success),
                ),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      if (!mounted) return;
      AppAlert.showLoading(context, 'Subiendo imagen QR...');

      final res = await ApiService().uploadPaymentMethodQr(id, picked.path);
      if (!mounted) return;
      AppAlert.hideLoading(context);

      await AppAlert.fromResponse(context, res, successMessage: '¡Código QR actualizado con éxito!');
      if (res['success'] == true) _loadPaymentMethods();
    } catch (e) {
      if (!mounted) return;
      AppAlert.hideLoading(context);
      AppAlert.error(context, 'Error al procesar imagen: $e');
    }
  }

  void _showQrPreviewDialog(String title, String imageUrl, String? instructions) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text('No se pudo cargar la imagen'),
                      ),
                    ),
                  ),
                ),
              ),
              if (instructions != null && instructions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  instructions,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditModal([Map<String, dynamic>? initialData]) {
    final isEditing = initialData != null;
    final nameCtrl = TextEditingController(text: initialData?['name'] ?? '');
    final instructionsCtrl = TextEditingController(text: initialData?['instructions'] ?? '');
    final bankCtrl = TextEditingController(text: initialData?['bank_name'] ?? '');
    final holderCtrl = TextEditingController(text: initialData?['account_holder'] ?? '');
    final numberCtrl = TextEditingController(text: initialData?['account_number'] ?? '');
    final phoneCtrl = TextEditingController(text: initialData?['phone_number'] ?? '');

    String selectedCode = initialData?['code'] ?? 'e_wallet';
    bool requiresReference = initialData?['requires_reference'] == true;
    bool isActive = initialData?['is_active'] ?? true;
    String? localQrPath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
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
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit_rounded : Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Editar Forma de Pago' : 'Nueva Forma de Pago',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tipo de medio de pago
                  const Text('Tipo de Categoría:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTypeChip('cash', 'Efectivo', Icons.payments_outlined, selectedCode, (val) {
                        setModalState(() => selectedCode = val);
                      }),
                      _buildTypeChip('e_wallet', 'Pago QR / Móvil', Icons.qr_code_2_rounded, selectedCode, (val) {
                        setModalState(() => selectedCode = val);
                      }),
                      _buildTypeChip('card', 'Tarjeta / POS', Icons.credit_card_rounded, selectedCode, (val) {
                        setModalState(() => selectedCode = val);
                      }),
                      _buildTypeChip('transfer', 'Transferencia', Icons.account_balance_rounded, selectedCode, (val) {
                        setModalState(() => selectedCode = val);
                      }),
                      _buildTypeChip('other', 'Otro', Icons.more_horiz_rounded, selectedCode, (val) {
                        setModalState(() => selectedCode = val);
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nombre visible
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Forma de Pago *',
                      hintText: 'Ej. QR Simple BNB, Tigo Money, Efectivo Bs.',
                      prefixIcon: Icon(Icons.label_outline_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Datos Bancarios (Opcionales para QR o Transferencia)
                  if (selectedCode != 'cash') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: bankCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Banco o Entidad',
                              hintText: 'Ej. Banco Unión, BNB',
                              prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono / Móvil',
                              hintText: 'Ej. 70012345',
                              prefixIcon: Icon(Icons.phone_android_rounded, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: numberCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nro. de Cuenta',
                              hintText: 'Ej. 100000456789',
                              prefixIcon: Icon(Icons.numbers_rounded, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: holderCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Titular de Cuenta',
                              hintText: 'Ej. Daniel Luna',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Instrucciones
                  TextField(
                    controller: instructionsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Instrucciones para el Cliente (Opcional)',
                      hintText: 'Ej. Escanee el QR desde su banco y muestre el comprobante al cajero.',
                      prefixIcon: Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Selector de Foto QR (si es QR o transferencia)
                  if (selectedCode == 'e_wallet' || selectedCode == 'transfer') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: localQrPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(File(localQrPath!), fit: BoxFit.cover),
                                  )
                                : (initialData?['qr_image_url'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(initialData!['qr_image_url'], fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.qr_code_2_rounded, color: AppColors.textSecondary, size: 36)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localQrPath != null
                                      ? 'Foto QR seleccionada'
                                      : (initialData?['qr_image_url'] != null ? 'QR actual cargado' : 'Sin foto QR'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Text(
                                  'Sube el QR de cobro de tu parqueo',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final src = await showModalBottomSheet<ImageSource>(
                                context: context,
                                builder: (subCtx) => SafeArea(
                                  child: Wrap(
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera_alt_rounded),
                                        title: const Text('Tomar Foto'),
                                        onTap: () => Navigator.pop(subCtx, ImageSource.camera),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.photo_library_rounded),
                                        title: const Text('Galería'),
                                        onTap: () => Navigator.pop(subCtx, ImageSource.gallery),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                              if (src != null) {
                                final img = await _picker.pickImage(source: src, imageQuality: 85);
                                if (img != null) {
                                  setModalState(() => localQrPath = img.path);
                                }
                              }
                            },
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: Text(localQrPath != null ? 'Cambiar' : 'Elegir'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Opciones: Referencia requerida y Activo
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exigir Nro. de Referencia / Comprobante', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Obliga a registrar el código de operación al cobrar', style: TextStyle(fontSize: 12)),
                    value: requiresReference,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => requiresReference = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Forma de Pago Activa', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Aparecerá disponible en la pantalla de salida y cobro', style: TextStyle(fontSize: 12)),
                    value: isActive,
                    activeColor: AppColors.success,
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
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) {
                          AppAlert.warning(context, 'Por favor escribe un nombre para la forma de pago.', title: 'Campo requerido');
                          return;
                        }

                        Navigator.pop(modalCtx);
                        AppAlert.showLoading(context, 'Guardando forma de pago...');

                        if (isEditing) {
                          final res = await ApiService().updatePaymentMethod(
                            initialData['id'] as int,
                            name: name,
                            code: selectedCode,
                            bankName: bankCtrl.text.trim().isNotEmpty ? bankCtrl.text.trim() : null,
                            accountHolder: holderCtrl.text.trim().isNotEmpty ? holderCtrl.text.trim() : null,
                            accountNumber: numberCtrl.text.trim().isNotEmpty ? numberCtrl.text.trim() : null,
                            phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                            instructions: instructionsCtrl.text.trim().isNotEmpty ? instructionsCtrl.text.trim() : null,
                            requiresReference: requiresReference,
                            isActive: isActive,
                            qrImagePath: localQrPath,
                          );

                          if (!mounted) return;
                          AppAlert.hideLoading(context);
                          await AppAlert.fromResponse(context, res, successMessage: 'Forma de pago actualizada con éxito');
                          if (res['success'] == true) _loadPaymentMethods();
                        } else {
                          final res = await ApiService().createPaymentMethod(
                            name: name,
                            code: selectedCode,
                            bankName: bankCtrl.text.trim().isNotEmpty ? bankCtrl.text.trim() : null,
                            accountHolder: holderCtrl.text.trim().isNotEmpty ? holderCtrl.text.trim() : null,
                            accountNumber: numberCtrl.text.trim().isNotEmpty ? numberCtrl.text.trim() : null,
                            phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                            instructions: instructionsCtrl.text.trim().isNotEmpty ? instructionsCtrl.text.trim() : null,
                            requiresReference: requiresReference,
                            isActive: isActive,
                            qrImagePath: localQrPath,
                          );

                          if (!mounted) return;
                          AppAlert.hideLoading(context);
                          await AppAlert.fromResponse(context, res, successMessage: 'Forma de pago registrada con éxito');
                          if (res['success'] == true) _loadPaymentMethods();
                        }
                      },
                      child: Text(isEditing ? 'Guardar Cambios' : 'Crear Forma de Pago', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildTypeChip(String code, String label, IconData icon, String current, Function(String) onSelect) {
    final isSelected = current == code;
    return ChoiceChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textPrimary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12)),
        ],
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      onSelected: (_) => onSelect(code),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  IconData _getIconForCode(String? code) {
    switch (code) {
      case 'cash':
        return Icons.payments_rounded;
      case 'e_wallet':
        return Icons.qr_code_2_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'transfer':
        return Icons.account_balance_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  Color _getColorForCode(String? code) {
    switch (code) {
      case 'cash':
        return const Color(0xFF10B981);
      case 'e_wallet':
        return const Color(0xFF3B82F6);
      case 'card':
        return const Color(0xFF8B5CF6);
      case 'transfer':
        return const Color(0xFFF59E0B);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Formas de Pago'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _loadPaymentMethods,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Forma', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditModal(),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadPaymentMethods,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 90),
                    children: [
                      // Banner informativo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.08),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_outlined, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestión de Cobros y QR',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Configura tus cuentas bancarias, sube la foto de tu QR Simple y activa o desactiva las opciones de cobro.',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_paymentMethods.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(Icons.payment_rounded, size: 60, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'Aún no hay formas de pago configuradas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Toca en "Nueva Forma" para agregar una.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._paymentMethods.map((method) {
                          final id = method['id'] as int;
                          final name = method['name'] ?? 'Forma de Pago';
                          final code = method['code'] ?? 'other';
                          final isActive = method['is_active'] == true;
                          final qrImageUrl = method['qr_image_url'] as String?;
                          final bankName = method['bank_name'] as String?;
                          final accountHolder = method['account_holder'] as String?;
                          final accountNumber = method['account_number'] as String?;
                          final phoneNumber = method['phone_number'] as String?;
                          final instructions = method['instructions'] as String?;
                          final requiresRef = method['requires_reference'] == true;

                          final methodColor = _getColorForCode(code);
                          final methodIcon = _getIconForCode(code);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? AppColors.cardBorder : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isActive ? 0.04 : 0.01),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Opacity(
                              opacity: isActive ? 1.0 : 0.65,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Icono, Nombre y Switch
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: methodColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Icon(methodIcon, color: methodColor, size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isActive)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade200,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Text('Inactivo', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                code == 'cash'
                                                    ? 'Pago en Efectivo'
                                                    : (code == 'e_wallet'
                                                        ? 'QR / Billetera Móvil'
                                                        : (code == 'card' ? 'Terminal POS / Tarjeta' : 'Transferencia Bancaria')),
                                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: isActive,
                                          activeColor: AppColors.success,
                                          onChanged: (val) => _toggleMethod(id, isActive),
                                        ),
                                      ],
                                    ),

                                    // Detalles bancarios si existen
                                    if (bankName != null || accountNumber != null || accountHolder != null || phoneNumber != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (bankName != null && bankName.isNotEmpty)
                                              Row(
                                                children: [
                                                  const Icon(Icons.account_balance_rounded, size: 14, color: AppColors.textSecondary),
                                                  const SizedBox(width: 6),
                                                  Text(bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                  if (accountNumber != null) ...[
                                                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                                                    Text('Cta: $accountNumber', style: const TextStyle(fontSize: 12)),
                                                  ],
                                                ],
                                              ),
                                            if (accountHolder != null && accountHolder.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text('Titular: $accountHolder', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ),
                                            if (phoneNumber != null && phoneNumber.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text('Teléfono / Móvil: $phoneNumber', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Instrucciones
                                    if (instructions != null && instructions.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        instructions,
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                                      ),
                                    ],

                                    // QR Preview or Upload CTA
                                    if (code == 'e_wallet' || code == 'transfer') ...[
                                      const SizedBox(height: 12),
                                      if (qrImageUrl != null)
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showQrPreviewDialog(name, qrImageUrl, instructions),
                                              child: Container(
                                                width: 52,
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.grey.shade300),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Image.network(qrImageUrl, fit: BoxFit.cover),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Código QR configurado',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                                                  ),
                                                  Text(
                                                    requiresRef ? 'Exige comprobante de pago' : 'No exige comprobante',
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              onPressed: () => _showQrPreviewDialog(name, qrImageUrl, instructions),
                                              icon: const Icon(Icons.fullscreen_rounded, size: 16),
                                              label: const Text('Ver QR', style: TextStyle(fontSize: 12)),
                                            ),
                                            const SizedBox(width: 6),
                                            IconButton(
                                              icon: const Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.primary),
                                              tooltip: 'Cambiar Foto QR',
                                              onPressed: () => _pickAndUploadQr(id, name),
                                            ),
                                          ],
                                        )
                                      else
                                        InkWell(
                                          onTap: () => _pickAndUploadQr(id, name),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: const Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primary),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Subir foto de Código QR para cobro',
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],

                                    const SizedBox(height: 12),
                                    const Divider(height: 1),
                                    const SizedBox(height: 6),

                                    // Botones inferiores: Editar y Eliminar
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (requiresRef)
                                          Container(
                                            margin: const EdgeInsets.only(right: 'auto' == 'auto' ? 8 : 0),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.tag_rounded, size: 12, color: Color(0xFFD97706)),
                                                SizedBox(width: 4),
                                                Text('Requiere Ref.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                                              ],
                                            ),
                                          ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: () => _showAddEditModal(method),
                                          icon: const Icon(Icons.edit_outlined, size: 16),
                                          label: const Text('Editar', style: TextStyle(fontSize: 12)),
                                        ),
                                        TextButton.icon(
                                          onPressed: () => _deleteMethod(id, name),
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                                          label: const Text('Eliminar', style: TextStyle(fontSize: 12, color: AppColors.error)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
