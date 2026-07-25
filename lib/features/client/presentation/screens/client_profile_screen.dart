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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (user != null) NotificationBell(userId: user.id),
            ]),
            UserAvatar(imageUrl: user?.profileImageUrl, initials: user?.initials ?? '?', size: 80),
            const SizedBox(height: 14),
            Text(user?.fullName ?? 'Cliente',
                style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            Text('@${user?.username ?? ''}',
                style: TextStyle(color: context.textSecondary)),
            const SizedBox(height: 32),
            _tile(context, Icons.person_outline_rounded, 'Editar perfil',
                () => context.push(AppRoutes.editProfile)),
            _tile(context, Icons.credit_card_outlined, 'Métodos de pago',
                () => context.push(AppRoutes.paymentMethods)),
            _tile(context, Icons.notifications_outlined, 'Notificaciones',
                () => context.push(AppRoutes.notifications)),
            _tile(context, Icons.report_gmailerrorred_outlined, 'Amonestaciones',
                () => context.push(AppRoutes.sanctions)),
            _tile(context, Icons.help_outline_rounded, 'Ayuda y ajustes',
                () => context.push(AppRoutes.settings)),
            _tile(context, Icons.logout_rounded, 'Cerrar sesión', () async {
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.welcome);
            }, color: AppTheme.alertRedLight),
          ]),
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
          if (color == null) Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.textHint),
        ]),
      ),
    );
  }
}
