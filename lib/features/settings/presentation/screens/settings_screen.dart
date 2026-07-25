// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/theme_mode_controller.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../sanctions/presentation/viewmodels/sanction_viewmodel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeControllerProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _SectionLabel('Apariencia'),
            _ThemeModeSelector(
              current: themeMode,
              onChanged: (m) => ref.read(themeModeControllerProvider.notifier).setMode(m),
            ),
            const SizedBox(height: 20),

            const _SectionLabel('Datos personales'),
            _tile(context, Icons.person_outline_rounded, 'Editar perfil',
                () => context.push(AppRoutes.editProfile)),
            _tile(context, Icons.lock_outline_rounded, 'Usuario y contraseña',
                () => _showChangePassword(context, ref)),
            const SizedBox(height: 20),

            const _SectionLabel('Legal'),
            _tile(context, Icons.privacy_tip_outlined, 'Política de privacidad',
                () => _showStaticInfo(context, 'Política de privacidad', _privacyText)),
            _tile(context, Icons.description_outlined, 'Condiciones de servicio',
                () => _showStaticInfo(context, 'Condiciones de servicio', _termsText)),
            const SizedBox(height: 20),

            const _SectionLabel('Soporte'),
            _tile(context, Icons.help_outline_rounded, 'Ayuda',
                () => _showHelpDialog(context, ref, user?.id)),
            const SizedBox(height: 20),

            _tile(context, Icons.logout_rounded, 'Cerrar sesión', () async {
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.welcome);
            }, color: AppTheme.alertRedLight),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.border, width: 0.5)),
        ),
        child: Row(children: [
          Icon(icon, color: color ?? context.textSecondary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color ?? context.textPrimary, fontSize: 14)),
          const Spacer(),
          if (color == null)
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.textHint),
        ]),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.card,
        title: Text('Nueva contraseña', style: TextStyle(color: ctx.textPrimary)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          style: TextStyle(color: ctx.textPrimary),
          decoration: const InputDecoration(hintText: 'Mínimo 6 caracteres'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final pass = ctrl.text.trim();
              Navigator.pop(ctx);
              if (pass.length < 6) {
                if (context.mounted) {
                  showAppSnackBar(context, 'La contraseña debe tener al menos 6 caracteres', isError: true);
                }
                return;
              }
              final ok = await ref.read(authViewModelProvider.notifier).changePassword(pass);
              if (context.mounted) {
                showAppSnackBar(context, ok ? 'Contraseña actualizada' : 'No se pudo actualizar', isError: !ok);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, WidgetRef ref, String? userId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.card,
        title: Text('¿En qué te ayudamos?', style: TextStyle(color: ctx.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: TextStyle(color: ctx.textPrimary),
          decoration: const InputDecoration(hintText: 'Describe tu duda o problema...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: userId == null
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await ref.read(sanctionViewModelProvider.notifier)
                        .requestSupportCall(userId, 'Ayuda general', message: ctrl.text);
                    if (context.mounted) showAppSnackBar(context, 'Enviamos tu solicitud a soporte');
                  },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showStaticInfo(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(controller: controller, children: [
            Text(title, style: TextStyle(color: ctx.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Text(body, style: TextStyle(color: ctx.textSecondary, fontSize: 13, height: 1.6)),
          ]),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;
  const _ThemeModeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [
      (ThemeMode.system, 'Sistema', Icons.brightness_auto_rounded),
      (ThemeMode.light, 'Claro', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Oscuro', Icons.dark_mode_rounded),
    ];
    return Row(
      children: options.map((o) {
        final (mode, label, icon) = o;
        final selected = current == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(mode),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected ? AppTheme.brandGreen : context.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? AppTheme.brandGreen : context.border),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 18, color: selected ? Colors.white : context.textSecondary),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.textSecondary,
                )),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

const _privacyText = '''
YO FREE-LANCER recopila los datos que compartes al registrarte (nombre, correo, teléfono, '''
    '''ubicación) para conectar clientes con YOERs cercanos. No compartimos tu información con '''
    '''terceros salvo lo necesario para completar un servicio contratado (por ejemplo, tu dirección '''
    '''con el YOER asignado). Puedes solicitar la eliminación de tu cuenta y datos en cualquier '''
    '''momento desde soporte.
''';

const _termsText = '''
Al usar YO FREE-LANCER aceptas comportarte con respeto hacia clientes y YOERs, cumplir con '''
    '''los servicios que aceptas o contratas, y pagar/recibir pagos a través de los métodos '''
    '''habilitados en la app. El incumplimiento reiterado puede derivar en amonestaciones, '''
    '''suspensión o baneo de la cuenta. Las tarifas y comisiones de la plataforma se muestran '''
    '''de forma transparente antes de confirmar cada reserva.
''';
