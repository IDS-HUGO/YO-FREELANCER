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
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const _SectionLabel('Apariencia'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _ThemeModeSelector(
                  current: themeMode,
                  onChanged: (m) => ref.read(themeModeControllerProvider.notifier).setMode(m),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            const _SectionLabel('Datos personales'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                _tile(context, Icons.person_outline_rounded, 'Editar perfil',
                    () => context.push(AppRoutes.editProfile)),
                const Divider(height: 1, indent: AppSpacing.huge),
                _tile(context, Icons.lock_outline_rounded, 'Usuario y contraseña',
                    () => _showChangePassword(context, ref)),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),

            const _SectionLabel('Legal'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                _tile(context, Icons.privacy_tip_outlined, 'Política de privacidad',
                    () => _showStaticInfo(context, 'Política de privacidad', _privacyText)),
                const Divider(height: 1, indent: AppSpacing.huge),
                _tile(context, Icons.description_outlined, 'Condiciones de servicio',
                    () => _showStaticInfo(context, 'Condiciones de servicio', _termsText)),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),

            const _SectionLabel('Soporte'),
            Card(
              clipBehavior: Clip.antiAlias,
              child: _tile(context, Icons.help_outline_rounded, 'Ayuda',
                  () => _showHelpDialog(context, ref, user?.id)),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Card(
              clipBehavior: Clip.antiAlias,
              child: _tile(context, Icons.logout_rounded, 'Cerrar sesión', () async {
                await ref.read(authViewModelProvider.notifier).logout();
                if (context.mounted) context.go(AppRoutes.welcome);
              }, color: context.colors.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? context.textSecondary),
      title: Text(
        label,
        style: color != null
            ? context.textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w600)
            : context.textTheme.bodyLarge,
      ),
      trailing: color == null
          ? Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.textHint)
          : null,
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva contraseña'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Mínimo 6 caracteres'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
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
              if (!context.mounted) return;
              if (ok) {
                showAppSnackBar(context, 'Contraseña actualizada');
              } else {
                final err = ref.read(authViewModelProvider).error;
                showAppErrorDialog(context, title: 'No se pudo actualizar la contraseña', message: err ?? 'Intenta de nuevo más tarde.');
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
        title: const Text('¿En qué te ayudamos?'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Describe tu duda o problema...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: userId == null
                ? null
                : () async {
                    Navigator.pop(ctx);
                    final ok = await ref.read(sanctionViewModelProvider.notifier)
                        .requestSupportCall(userId, 'Ayuda general', message: ctrl.text);
                    if (!context.mounted) return;
                    if (ok) {
                      showAppSnackBar(context, 'Enviamos tu solicitud a soporte');
                    } else {
                      showAppErrorDialog(
                        context,
                        title: 'No se pudo enviar tu solicitud',
                        message: 'Intenta de nuevo más tarde.',
                      );
                    }
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
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ListView(controller: controller, children: [
            Text(title, style: ctx.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            Text(body, style: ctx.textTheme.bodyMedium?.copyWith(height: 1.6)),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
    return SegmentedButton<ThemeMode>(
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('Sistema'),
          icon: Icon(Icons.brightness_auto_rounded, size: 18),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('Claro'),
          icon: Icon(Icons.light_mode_rounded, size: 18),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('Oscuro'),
          icon: Icon(Icons.dark_mode_rounded, size: 18),
        ),
      ],
      selected: {current},
      onSelectionChanged: (selection) => onChanged(selection.first),
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
