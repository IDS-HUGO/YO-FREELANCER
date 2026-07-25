import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: NotificationBell(userId: user.id),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              UserAvatar(
                imageUrl: user?.profileImageUrl,
                initials: user?.initials ?? '?',
                size: 88,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                user?.fullName ?? 'Cliente',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '@${user?.username ?? ''}',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _tile(context, Icons.person_outline_rounded, 'Editar perfil',
                        () => context.push(AppRoutes.editProfile)),
                    const Divider(height: 1),
                    _tile(context, Icons.credit_card_outlined, 'Métodos de pago',
                        () => context.push(AppRoutes.paymentMethods)),
                    const Divider(height: 1),
                    _tile(context, Icons.notifications_outlined, 'Notificaciones',
                        () => context.push(AppRoutes.notifications)),
                    const Divider(height: 1),
                    _tile(context, Icons.report_gmailerrorred_outlined, 'Amonestaciones',
                        () => context.push(AppRoutes.sanctions)),
                    const Divider(height: 1),
                    _tile(context, Icons.help_outline_rounded, 'Ayuda y ajustes',
                        () => context.push(AppRoutes.settings)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(children: [
          Icon(icon, color: color ?? context.colors.onSurfaceVariant, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: color ?? context.colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (color == null)
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.colors.outline),
        ]),
      ),
    );
  }
}
