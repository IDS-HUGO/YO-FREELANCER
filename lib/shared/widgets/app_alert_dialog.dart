// lib/shared/widgets/app_alert_dialog.dart
import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

enum AlertType { success, error, warning, info }

class AppAlertDialog extends StatefulWidget {
  final AlertType type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppAlertDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  static Future<void> show(
    BuildContext context, {
    required AlertType type,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return AppAlertDialog(
          type: type,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AppAlertDialog> createState() => _AppAlertDialogState();
}

class _AppAlertDialogState extends State<AppAlertDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconAnimController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.elasticOut,
    );
    _iconAnimController.forward();
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    // Colores personalizados por tipo
    Color primaryColor;
    IconData iconData;
    List<Color> gradientColors;

    switch (widget.type) {
      case AlertType.success:
        primaryColor = AppTheme.brandGreen;
        iconData = Icons.check_circle_outline_rounded;
        gradientColors = isDark
            ? [AppTheme.brandGreen.withValues(alpha: 0.15), AppTheme.brandGreenDark.withValues(alpha: 0.05)]
            : [AppTheme.brandGreenAccent.withValues(alpha: 0.4), AppTheme.brandGreen.withValues(alpha: 0.1)];
        break;
      case AlertType.error:
        primaryColor = AppTheme.alertRedLight;
        iconData = Icons.error_outline_rounded;
        gradientColors = isDark
            ? [AppTheme.alertRed.withValues(alpha: 0.2), AppTheme.bgDark.withValues(alpha: 0.1)]
            : [const Color(0xFFFFDAD6), const Color(0xFFFFECEB)];
        break;
      case AlertType.warning:
        primaryColor = AppTheme.warningOrange;
        iconData = Icons.warning_amber_rounded;
        gradientColors = isDark
            ? [AppTheme.warningOrange.withValues(alpha: 0.15), AppTheme.bgDark.withValues(alpha: 0.05)]
            : [const Color(0xFFFFE4B8), const Color(0xFFFFF6E6)];
        break;
      case AlertType.info:
        primaryColor = AppTheme.infoBlue;
        iconData = Icons.info_outline_rounded;
        gradientColors = isDark
            ? [AppTheme.infoBlue.withValues(alpha: 0.15), AppTheme.bgDark.withValues(alpha: 0.05)]
            : [const Color(0xFFD0E1FD), const Color(0xFFEDF4FE)];
        break;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: AppRadius.xxlR,
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera con gradiente y el icono animado
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradientColors,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xxl - 1.5),
                ),
              ),
              child: Center(
                child: ScaleTransition(
                  scale: _iconScale,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.surfaceDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: Icon(
                      iconData,
                      size: 44,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ),

            // Contenido de texto
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                children: [
                  if (widget.actionLabel != null && widget.onAction != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (widget.onAction != null) {
                          widget.onAction!();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: Size.zero,
                        elevation: 0,
                      ),
                      child: Text(
                        widget.actionLabel ?? 'Entendido',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
