// lib/features/yoer/presentation/screens/yoer_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/domain/entities/user_entity.dart';

class YoerProfileScreen extends ConsumerWidget {
  const YoerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // Cover
            Stack(children: [
              Container(
                height: 160,
                decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
              ),
              Positioned(
                bottom: -40, left: 24,
                child: UserAvatar(
                  imageUrl: user?.profileImageUrl,
                  initials: user?.initials ?? '?',
                  size: 80,
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: IconButton(
                  onPressed: () => context.push(AppRoutes.editProfile),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 52),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.fullName ?? 'YOER',
                        style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('@${user?.username ?? 'usuario'}',
                        style: TextStyle(color: context.textSecondary, fontSize: 13)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.4)),
                    ),
                    child: Text(user?.status.displayName ?? 'Disponible',
                        style: const TextStyle(color: AppTheme.brandGreen,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),

                if (user?.bio != null) ...[
                  Text(user!.bio!,
                      style: TextStyle(color: context.textSecondary, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 16),
                ],

                // Métricas
                Row(children: [
                  _stat(context, user?.rating.toStringAsFixed(1) ?? '0.0', 'Rating', Icons.star_rounded),
                  _stat(context, '${user?.totalReviews ?? 0}', 'Reseñas', Icons.reviews_outlined),
                  _stat(context, '${user?.completedJobs ?? 0}', 'Trabajos', Icons.check_circle_outline_rounded),
                ]),
                const SizedBox(height: 24),

                // Localización
                if (user?.city != null)
                  _infoRow(context, Icons.location_on_outlined, '${user?.city}, ${user?.country}'),
                if (user?.phoneNumber != null)
                  _infoRow(context, Icons.phone_outlined, user!.phoneNumber!),
                _infoRow(context, Icons.mail_outline_rounded, user?.email ?? ''),

                const SizedBox(height: 28),
                Divider(color: context.border),
                const SizedBox(height: 20),

                // Acciones
                _actionTile(context, Icons.person_outline_rounded, 'Editar perfil',
                    () => context.push(AppRoutes.editProfile)),
                _actionTile(context, Icons.store_outlined, 'Mi portafolio (Vitrina)',
                    () => context.push(AppRoutes.yoerVitrina)),
                _actionTile(context, Icons.emoji_events_outlined, 'Insignias',
                    () => context.push(AppRoutes.badges)),
                _actionTile(context, Icons.leaderboard_outlined, 'Ranking',
                    () => context.push(AppRoutes.ranking)),
                _actionTile(context, Icons.account_balance_wallet_outlined, 'YOER Cash',
                    () => context.push(AppRoutes.yoerWallet)),
                _actionTile(context, Icons.volunteer_activism_outlined, 'Voluntariado',
                    () => context.push(AppRoutes.volunteering)),
                _actionTile(context, Icons.star_border_rounded, 'Modo Artista / Talento',
                    () => context.push(AppRoutes.artistMode)),
                _actionTile(context, Icons.notifications_outlined, 'Notificaciones',
                    () => context.push(AppRoutes.notifications)),
                _actionTile(context, Icons.report_gmailerrorred_outlined, 'Amonestaciones',
                    () => context.push(AppRoutes.sanctions)),
                _actionTile(context, Icons.security_outlined, 'Seguridad, privacidad y ayuda',
                    () => context.push(AppRoutes.settings)),
                const SizedBox(height: 8),
                _actionTile(context, Icons.logout_rounded, 'Cerrar sesión', () async {
                  await ref.read(authViewModelProvider.notifier).logout();
                }, color: AppTheme.alertRedLight),
                const SizedBox(height: 40),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border, width: 0.5),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.brandGreen, size: 18),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: context.textHint, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: context.textSecondary, size: 18),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: context.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: color ?? context.textSecondary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color ?? context.textPrimary, fontSize: 14)),
          const Spacer(),
          if (color == null) Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: context.textHint),
        ]),
      ),
    );
  }
}
