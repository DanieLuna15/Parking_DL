import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tipos de alerta estilo SweetAlert.
enum AlertType { success, error, warning, info, question }

/// Utilidad global de alertas estilo SweetAlert (Swal) para toda la app.
///
/// Uso:
///   AppAlert.success(context, 'Vehículo registrado');
///   AppAlert.error(context, 'No se pudo conectar');
///   final ok = await AppAlert.confirm(context, title: '¿Eliminar?', message: '...');
///   AppAlert.showLoading(context, 'Guardando...'); ... AppAlert.hideLoading(context);
class AppAlert {
  AppAlert._();

  static bool _loadingVisible = false;

  // ---------------------------------------------------------------------------
  // API pública
  // ---------------------------------------------------------------------------

  static Future<void> success(
    BuildContext context,
    String message, {
    String title = '¡Éxito!',
    String confirmText = 'Aceptar',
    Duration? autoClose = const Duration(milliseconds: 2200),
  }) {
    return show(
      context,
      type: AlertType.success,
      title: title,
      message: message,
      confirmText: confirmText,
      autoClose: autoClose,
    );
  }

  static Future<void> error(
    BuildContext context,
    String message, {
    String title = '¡Ups! Ocurrió un error',
    String confirmText = 'Entendido',
  }) {
    return show(
      context,
      type: AlertType.error,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> warning(
    BuildContext context,
    String message, {
    String title = 'Atención',
    String confirmText = 'Entendido',
  }) {
    return show(
      context,
      type: AlertType.warning,
      title: title,
      message: message,
      confirmText: confirmText,
    );
  }

  static Future<void> info(
    BuildContext context,
    String message, {
    String title = 'Información',
    String confirmText = 'Aceptar',
    Duration? autoClose,
  }) {
    return show(
      context,
      type: AlertType.info,
      title: title,
      message: message,
      confirmText: confirmText,
      autoClose: autoClose,
    );
  }

  /// Muestra éxito o error según la respuesta estándar del API `{success, message}`.
  static Future<void> fromResponse(
    BuildContext context,
    Map<String, dynamic> res, {
    String? successMessage,
    String? errorMessage,
  }) {
    if (res['success'] == true) {
      return success(context, successMessage ?? res['message'] ?? 'Operación realizada correctamente');
    }
    final isConn = res['is_connection_error'] == true;
    return error(
      context,
      errorMessage ?? res['message'] ?? 'No se pudo completar la operación',
      title: isConn ? 'Sin conexión' : '¡Ups! Ocurrió un error',
    );
  }

  /// Confirmación con botones Sí / Cancelar. Devuelve `true` si confirma.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Sí, continuar',
    String cancelText = 'Cancelar',
    bool destructive = false,
  }) async {
    final result = await _present<bool>(
      context,
      barrierDismissible: true,
      builder: (ctx) => _AlertCard(
        type: destructive ? AlertType.warning : AlertType.question,
        title: title,
        message: message,
        actions: [
          Expanded(
            child: _AlertButton(
              label: cancelText,
              color: AppColors.textSecondary,
              outlined: true,
              onTap: () => Navigator.of(ctx).pop(false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AlertButton(
              label: confirmText,
              color: destructive ? AppColors.error : AppColors.primary,
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Muestra un loader modal (no se puede cerrar tocando fuera).
  static void showLoading(BuildContext context, [String message = 'Procesando...']) {
    if (_loadingVisible) return;
    _loadingVisible = true;
    _present<void>(
      context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: _LoadingCard(message: message),
      ),
    ).whenComplete(() => _loadingVisible = false);
  }

  static void hideLoading(BuildContext context) {
    if (!_loadingVisible) return;
    _loadingVisible = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Alerta genérica.
  static Future<void> show(
    BuildContext context, {
    required AlertType type,
    required String title,
    required String message,
    String confirmText = 'Aceptar',
    Duration? autoClose,
  }) async {
    if (!context.mounted) return;
    Timer? timer;
    await _present<void>(
      context,
      barrierDismissible: true,
      builder: (ctx) {
        if (autoClose != null) {
          timer = Timer(autoClose, () {
            if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
          });
        }
        return _AlertCard(
          type: type,
          title: title,
          message: message,
          autoClose: autoClose,
          actions: [
            Expanded(
              child: _AlertButton(
                label: confirmText,
                color: _colorFor(type),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        );
      },
    );
    timer?.cancel();
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  static Future<T?> _present<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'alert',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (ctx, _, __) => Center(child: builder(ctx)),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.7, end: 1.0).animate(curved), child: child),
        );
      },
    );
  }

  static Color _colorFor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return AppColors.success;
      case AlertType.error:
        return AppColors.error;
      case AlertType.warning:
        return AppColors.warning;
      case AlertType.info:
        return AppColors.secondary;
      case AlertType.question:
        return AppColors.primary;
    }
  }
}

// =============================================================================
// Widgets visuales
// =============================================================================

class _AlertCard extends StatelessWidget {
  final AlertType type;
  final String title;
  final String message;
  final List<Widget> actions;
  final Duration? autoClose;

  const _AlertCard({
    required this.type,
    required this.title,
    required this.message,
    required this.actions,
    this.autoClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppAlert._colorFor(type);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: math.min(MediaQuery.of(context).size.width * 0.86, 380),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedAlertIcon(type: type, color: color),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            Row(children: actions),
            if (autoClose != null) ...[
              const SizedBox(height: 14),
              _TimerBar(duration: autoClose!, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _AlertButton({required this.label, required this.color, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
    );
  }
}

class _TimerBar extends StatelessWidget {
  final Duration duration;
  final Color color;
  const _TimerBar({required this.duration, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: duration,
      builder: (_, v, __) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 4,
          backgroundColor: color.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String message;
  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(strokeWidth: 4.5, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icono animado tipo SweetAlert: círculo que se dibuja + símbolo.
class _AnimatedAlertIcon extends StatefulWidget {
  final AlertType type;
  final Color color;
  const _AnimatedAlertIcon({required this.type, required this.color});

  @override
  State<_AnimatedAlertIcon> createState() => _AnimatedAlertIconState();
}

class _AnimatedAlertIconState extends State<_AnimatedAlertIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 750))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _IconPainter(type: widget.type, color: widget.color, progress: _c.value),
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final AlertType type;
  final Color color;
  final double progress;

  _IconPainter({required this.type, required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;

    // 1) Círculo que se dibuja (0 → 0.5)
    final circleT = (progress / 0.5).clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2,
        2 * math.pi * Curves.easeOut.transform(circleT), false, stroke);

    // 2) Símbolo (0.45 → 1.0)
    final t = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
    if (t <= 0) return;
    final s = size.width;

    switch (type) {
      case AlertType.success:
        final p1 = Offset(s * 0.30, s * 0.52);
        final p2 = Offset(s * 0.44, s * 0.65);
        final p3 = Offset(s * 0.71, s * 0.37);
        final path = Path()..moveTo(p1.dx, p1.dy);
        if (t < 0.4) {
          final k = t / 0.4;
          path.lineTo(p1.dx + (p2.dx - p1.dx) * k, p1.dy + (p2.dy - p1.dy) * k);
        } else {
          final k = (t - 0.4) / 0.6;
          path
            ..lineTo(p2.dx, p2.dy)
            ..lineTo(p2.dx + (p3.dx - p2.dx) * k, p2.dy + (p3.dy - p2.dy) * k);
        }
        canvas.drawPath(path, stroke);
        break;

      case AlertType.error:
        final a = s * 0.34, b = s * 0.66;
        final k1 = (t / 0.5).clamp(0.0, 1.0);
        final k2 = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
        canvas.drawLine(Offset(a, a), Offset(a + (b - a) * k1, a + (b - a) * k1), stroke);
        if (k2 > 0) canvas.drawLine(Offset(b, a), Offset(b - (b - a) * k2, a + (b - a) * k2), stroke);
        break;

      case AlertType.warning:
      case AlertType.info:
        final isInfo = type == AlertType.info;
        final top = s * (isInfo ? 0.44 : 0.28);
        final bottom = s * (isInfo ? 0.72 : 0.58);
        canvas.drawLine(Offset(s / 2, top), Offset(s / 2, top + (bottom - top) * t), stroke);
        if (t > 0.7) {
          final dot = Paint()..color = color;
          canvas.drawCircle(Offset(s / 2, s * (isInfo ? 0.31 : 0.71)), 3.6, dot);
        }
        break;

      case AlertType.question:
        final tp = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(fontSize: s * 0.48, fontWeight: FontWeight.w800, color: color.withValues(alpha: t)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) => old.progress != progress;
}
