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
      body: CustomScrollView(
        slivers: [
          // ── Portada con degradado de marca ─────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: context.bg,
            title: Text(user?.fullName ?? 'YOER', style: context.textTheme.titleMedium),
            flexibleSpace: const FlexibleSpaceBar(
              background: DecoratedBox(decoration: BoxDecoration(gradient: AppTheme.greenGradient)),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push(AppRoutes.editProfile),
                icon: const Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(foregroundColor: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar superpuesto a la portada
              Container(
                margin: const EdgeInsets.only(top: -40, left: AppSpacing.xxl),
                child: UserAvatar(
                  imageUrl: user?.profileImageUrl,
                  initials: user?.initials ?? '?',
                  size: 80,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user?.fullName ?? 'YOER', style: context.textTheme.headlineSmall),
                      Text('@${user?.username ?? 'usuario'}', style: context.textTheme.bodyMedium),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withValues(alpha: 0.15),
                        borderRadius: AppRadius.pillR,
                        border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.4)),
                      ),
                      child: Text(user?.status.displayName ?? 'Disponible',
                          style: const TextStyle(color: AppTheme.brandGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),

                  if (user?.bio != null) ...[
                    Text(user!.bio!, style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Métricas
                  Row(children: [
                    _stat(context, user?.rating.toStringAsFixed(1) ?? '0.0', 'Rating', Icons.star_rounded),
                    _stat(context, '${user?.totalReviews ?? 0}', 'Reseñas', Icons.reviews_outlined),
                    _stat(context, '${user?.completedJobs ?? 0}', 'Trabajos', Icons.check_circle_outline_rounded),
                  ]),
                  const SizedBox(height: AppSpacing.xxl),

                  // Localización
                  if (user?.city != null)
                    _infoRow(context, Icons.location_on_outlined, '${user?.city}, ${user?.country}'),
                  if (user?.phoneNumber != null)
                    _infoRow(context, Icons.phone_outlined, user!.phoneNumber!),
                  _infoRow(context, Icons.mail_outline_rounded, user?.email ?? ''),

                  const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                  const Divider(),
                  const SizedBox(height: AppSpacing.xl),

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
                  const SizedBox(height: AppSpacing.sm),
                  _actionTile(context, Icons.logout_rounded, 'Cerrar sesión', () async {
                    await ref.read(authViewModelProvider.notifier).logout();
                  }, color: context.colors.error),
                  const SizedBox(height: AppSpacing.xxxl + AppSpacing.sm),
                ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md - 2),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Column(children: [
              Icon(icon, color: AppTheme.brandGreen, size: 18),
              const SizedBox(height: AppSpacing.xs + 2),
              Text(value, style: context.textTheme.titleMedium),
              Text(label, style: context.textTheme.labelSmall),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Row(children: [
        Icon(icon, color: context.textSecondary, size: 18),
        const SizedBox(width: AppSpacing.sm + 2),
        Text(text, style: context.textTheme.bodyMedium?.copyWith(fontSize: 13)),
      ]),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgR,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        child: Row(children: [
          Icon(icon, color: color ?? context.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.md + 2),
          Text(label, style: context.textTheme.bodyMedium?.copyWith(color: color ?? context.textPrimary, fontSize: 14)),
          const Spacer(),
          if (color == null) Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.textHint),
        ]),
      ),
    );
  }
}
