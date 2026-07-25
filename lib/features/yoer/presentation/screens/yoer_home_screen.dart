// lib/features/yoer/presentation/screens/yoer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../bookings/data/datasources/booking_remote_datasource.dart';
import '../../../tasks/presentation/viewmodels/radar_viewmodel.dart';
import '../../../../shared/widgets/daily_phrase.dart';

class YoerHomeScreen extends ConsumerStatefulWidget {
  const YoerHomeScreen({super.key});
  @override
  ConsumerState<YoerHomeScreen> createState() => _YoerHomeScreenState();
}

class _YoerHomeScreenState extends ConsumerState<YoerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        ref.read(bookingViewModelProvider.notifier).loadBookingsForYoer(user.id);
      }
      ref.read(radarViewModelProvider.notifier).loadUrgentTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user         = ref.watch(currentUserProvider);
    final bookingState = ref.watch(bookingViewModelProvider);
    final urgentCount  = ref.watch(radarViewModelProvider).urgentTasks.length;

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header colapsable ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            centerTitle: false,
            backgroundColor: context.bg,
            expandedHeight: 132,
            title: Text(user?.firstName ?? 'YOER', style: context.textTheme.titleMedium),
            actions: [
              if (user != null) NotificationBell(userId: user.id),
              const SizedBox(width: AppSpacing.sm),
              _iconBtn(Icons.report_gmailerrorred_outlined,
                  () => context.push(AppRoutes.sanctions), color: context.colors.error),
              const SizedBox(width: AppSpacing.lg),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl, AppSpacing.huge, AppSpacing.huge, AppSpacing.lg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    UserAvatar(
                      imageUrl: user?.profileImageUrl,
                      initials: user?.initials ?? '?',
                      size: 52,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.firstName ?? 'YOER', style: context.textTheme.titleLarge),
                          Row(children: [
                            Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(color: _statusColor(user?.status), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: AppSpacing.xs + 1),
                            Text(user?.status.displayName ?? 'Disponible',
                                style: context.textTheme.bodySmall?.copyWith(color: _statusColor(user?.status))),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  Text(dailyYoerPhrase(),
                      style: context.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Card disponibilidad ────────────────────────────────
                  Card(
                    child: InkWell(
                      borderRadius: AppRadius.xlR,
                      onTap: () => _showAvailabilityPicker(context, user),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl, vertical: AppSpacing.lg,
                        ),
                        child: Row(children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: _statusColor(user?.status), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Text(user?.status.displayName ?? 'Disponible',
                              style: context.textTheme.titleSmall?.copyWith(color: _statusColor(user?.status))),
                          const Spacer(),
                          Text('CAMBIAR',
                              style: context.textTheme.labelMedium?.copyWith(
                                color: context.textPrimary, fontWeight: FontWeight.w700,
                              )),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Bono semanal (calculado con tareas completadas reales) ──
                  Builder(builder: (context) {
                    const weeklyTarget = 10;
                    final now = DateTime.now();
                    final weekStart = now.subtract(Duration(days: now.weekday - 1));
                    final completedThisWeek = bookingState.completedBookings
                        .where((b) => b.completedAt != null && b.completedAt!.isAfter(weekStart))
                        .length;
                    final progress = (completedThisWeek / weeklyTarget).clamp(0.0, 1.0);
                    final remaining = (weeklyTarget - completedThisWeek).clamp(0, weeklyTarget);

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text('Bono Sorpresa Semanal', style: context.textTheme.titleSmall)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.brandGreen.withValues(alpha: 0.15),
                                borderRadius: AppRadius.pillR,
                              ),
                              child: Text('$completedThisWeek / $weeklyTarget TAREAS',
                                  style: const TextStyle(
                                    color: AppTheme.brandGreen, fontSize: 10, fontWeight: FontWeight.w800,
                                  )),
                            ),
                          ]),
                          const SizedBox(height: AppSpacing.lg),
                          ClipRRect(
                            borderRadius: AppRadius.smR,
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: context.colors.surfaceContainerHighest,
                              valueColor: const AlwaysStoppedAnimation(AppTheme.brandGreen),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            remaining == 0
                                ? '¡Bono desbloqueado esta semana!'
                                : '¡Te faltan $remaining tareas para desbloquear el bono!',
                            style: context.textTheme.bodySmall,
                          ),
                        ]),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.xxxl),

                  // ── Oportunidades ───────────────────────────────────────
                  SectionCard(
                    title: 'Oportunidades en tiempo real',
                    action: 'Abrir Radar',
                    onAction: () => context.push(AppRoutes.yoerRadar),
                    child: _urgentCard(urgentCount),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // ── Próxima jornada ──────────────────────────────────────
                  SectionCard(
                    title: 'Próxima jornada',
                    action: 'Mi agenda',
                    onAction: () => context.push(AppRoutes.yoerAgenda),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: bookingState.isLoading
                          ? const Padding(
                              key: ValueKey('loading'),
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                              child: Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
                            )
                          : bookingState.upcomingBookings.isEmpty
                              ? _emptyBookings(key: const ValueKey('empty'))
                              : Column(
                                  key: const ValueKey('list'),
                                  children: bookingState.upcomingBookings
                                      .take(2)
                                      .map((b) => _bookingCard(b))
                                      .toList(),
                                ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // ── Métricas rápidas ─────────────────────────────────────
                  SectionCard(
                    title: 'Tu rendimiento',
                    child: Row(children: [
                      _metricCard('Completados', '${user?.completedJobs ?? 0}', Icons.check_circle_outline_rounded),
                      const SizedBox(width: AppSpacing.md),
                      _metricCard('Rating', '${user?.rating.toStringAsFixed(1) ?? '0.0'} ⭐', Icons.star_outline_rounded),
                      const SizedBox(width: AppSpacing.md),
                      _metricCard('Bono', '\$${user?.weeklyBonus.toStringAsFixed(0) ?? '0'}', Icons.card_giftcard_rounded),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.xxxl + AppSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(UserStatus? status) {
    switch (status) {
      case UserStatus.ocupado:      return AppTheme.warningOrange;
      case UserStatus.noDisponible: return context.textHint;
      case UserStatus.warned:       return context.colors.error;
      case UserStatus.disponible:
      case null:
        return AppTheme.brandGreen;
    }
  }

  void _showAvailabilityPicker(BuildContext context, UserEntity? user) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('¿Cuál es tu disponibilidad?', style: context.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.lg),
            ...[UserStatus.disponible, UserStatus.ocupado, UserStatus.noDisponible].map((s) {
              return ListTile(
                leading: Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle)),
                title: Text(s.displayName),
                trailing: user.status == s ? const Icon(Icons.check_rounded, color: AppTheme.brandGreen) : null,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authViewModelProvider.notifier).updateProfile(user.copyWith(status: s));
                },
              );
            }),
          ]),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: color ?? context.textSecondary,
        side: BorderSide(color: color != null ? color.withValues(alpha: 0.5) : context.border),
      ),
    );
  }

  Widget _urgentCard(int urgentCount) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.xlR,
        onTap: () => context.push(AppRoutes.yoerRadar),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: context.cardInner,
                borderRadius: AppRadius.mdR,
              ),
              child: const Icon(Icons.flash_on_rounded, color: AppTheme.brandGreen, size: 22),
            ),
            const SizedBox(width: AppSpacing.md + 2),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TAREAS URGENTES', style: context.textTheme.titleSmall),
              Text(
                urgentCount == 0 ? 'Sin tareas urgentes por ahora' : '$urgentCount tareas cerca de ti',
                style: context.textTheme.bodySmall,
              ),
            ])),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textHint),
          ]),
        ),
      ),
    );
  }

  Widget _emptyBookings({Key? key}) {
    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(children: [
          Icon(Icons.calendar_today_outlined, color: context.textHint, size: 40),
          const SizedBox(height: AppSpacing.md),
          Text('Sin trabajos programados', style: context.textTheme.bodyMedium),
        ]),
      ),
    );
  }

  Widget _bookingCard(BookingEntity b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Card(
        child: InkWell(
          borderRadius: AppRadius.xlR,
          onTap: () => context.push('/booking/${b.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md + 2),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: context.cardInner, borderRadius: AppRadius.mdR),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(b.scheduledTime,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.textPrimary, fontWeight: FontWeight.w700,
                      )),
                  Text('AM', style: context.textTheme.labelSmall?.copyWith(fontSize: 9)),
                ]),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.serviceName, style: context.textTheme.titleSmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Con ${b.clientName}', style: context.textTheme.bodySmall),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${b.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
                BookingStatusChip(status: b.status.name),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md + 2),
          child: Column(children: [
            Icon(icon, color: AppTheme.brandGreen, size: 20),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: context.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(label, style: context.textTheme.labelSmall, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
