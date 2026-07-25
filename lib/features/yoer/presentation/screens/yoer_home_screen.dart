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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // ── Header ──────────────────────────────────────────────────
              Row(children: [
                UserAvatar(
                  imageUrl: user?.profileImageUrl,
                  initials: user?.initials ?? '?',
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.firstName ?? 'YOER',
                      style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  Row(children: [
                    Container(width: 7, height: 7,
                        decoration: BoxDecoration(color: _statusColor(user?.status), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(user?.status.displayName ?? 'Disponible',
                        style: TextStyle(color: _statusColor(user?.status), fontSize: 12)),
                  ]),
                ])),
                // Botones icono
                if (user != null) NotificationBell(userId: user.id),
                const SizedBox(width: 8),
                _iconBtn(Icons.report_gmailerrorred_outlined,
                    () => context.push(AppRoutes.sanctions), color: AppTheme.alertRed),
              ]),
              const SizedBox(height: 14),
              Text(dailyYoerPhrase(),
                  style: TextStyle(color: context.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 28),

              // ── Card disponibilidad ────────────────────────────────────
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(color: _statusColor(user?.status), shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(user?.status.displayName ?? 'Disponible',
                      style: TextStyle(color: _statusColor(user?.status), fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAvailabilityPicker(context, user),
                    child: Text('CAMBIAR',
                        style: TextStyle(color: context.textPrimary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

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

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [context.card, context.cardInner],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border, width: 0.5),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text('Bono Sorpresa Semanal',
                          style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.brandGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$completedThisWeek / $weeklyTarget TAREAS',
                            style: const TextStyle(color: AppTheme.brandGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.black38,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.brandGreen),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      remaining == 0
                          ? '¡Bono desbloqueado esta semana!'
                          : '¡Te faltan $remaining tareas para desbloquear el bono!',
                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 32),

              // ── Oportunidades ──────────────────────────────────────────
              SectionCard(
                title: 'Oportunidades en tiempo real',
                action: 'Abrir Radar',
                onAction: () => context.push(AppRoutes.yoerRadar),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.yoerRadar),
                  child: _urgentCard(urgentCount),
                ),
              ),
              const SizedBox(height: 32),

              // ── Próxima jornada ────────────────────────────────────────
              SectionCard(
                title: 'Próxima jornada',
                action: 'Mi agenda',
                onAction: () => context.push(AppRoutes.yoerAgenda),
                child: bookingState.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                    : bookingState.upcomingBookings.isEmpty
                        ? _emptyBookings()
                        : Column(
                            children: bookingState.upcomingBookings
                                .take(2)
                                .map((b) => _bookingCard(b, context))
                                .toList(),
                          ),
              ),
              const SizedBox(height: 32),

              // ── Métricas rápidas ───────────────────────────────────────
              SectionCard(
                title: 'Tu rendimiento',
                child: Row(children: [
                  _metricCard('Completados', '${user?.completedJobs ?? 0}', Icons.check_circle_outline_rounded),
                  const SizedBox(width: 12),
                  _metricCard('Rating', '${user?.rating.toStringAsFixed(1) ?? '0.0'} ⭐', Icons.star_outline_rounded),
                  const SizedBox(width: 12),
                  _metricCard('Bono', '\$${user?.weeklyBonus.toStringAsFixed(0) ?? '0'}', Icons.card_giftcard_rounded),
                ]),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(UserStatus? status) {
    switch (status) {
      case UserStatus.ocupado:      return AppTheme.warningOrange;
      case UserStatus.noDisponible: return context.textHint;
      case UserStatus.warned:       return AppTheme.alertRedLight;
      case UserStatus.disponible:
      case null:
        return AppTheme.brandGreen;
    }
  }

  void _showAvailabilityPicker(BuildContext context, UserEntity? user) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('¿Cuál es tu disponibilidad?',
                style: TextStyle(color: context.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...[UserStatus.disponible, UserStatus.ocupado, UserStatus.noDisponible].map((s) {
              return ListTile(
                leading: Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle)),
                title: Text(s.displayName, style: TextStyle(color: context.textPrimary)),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          border: Border.all(
            color: color != null ? color.withValues(alpha: 0.5) : context.border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20,
            color: color ?? context.textSecondary),
      ),
    );
  }

  Widget _urgentCard(int urgentCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: context.cardInner,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.flash_on_rounded, color: AppTheme.brandGreen, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('TAREAS URGENTES',
              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(
            urgentCount == 0 ? 'Sin tareas urgentes por ahora' : '$urgentCount tareas cerca de ti',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ])),
        Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: context.textHint),
      ]),
    );
  }

  Widget _emptyBookings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(children: [
        Icon(Icons.calendar_today_outlined,
            color: context.textHint, size: 40),
        const SizedBox(height: 12),
        Text('Sin trabajos programados',
            style: TextStyle(color: context.textSecondary, fontSize: 14)),
      ]),
    );
  }

  Widget _bookingCard(BookingEntity b, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/booking/${b.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.border, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: context.cardInner,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(b.scheduledTime,
                  style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('AM', style: TextStyle(color: context.textHint, fontSize: 9)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName, style: TextStyle(
                color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Con ${b.clientName}',
                style: TextStyle(color: context.textSecondary, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${b.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(color: AppTheme.brandGreen,
                    fontSize: 15, fontWeight: FontWeight.w800)),
            BookingStatusChip(status: b.status.name),
          ]),
        ]),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border, width: 0.5),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.brandGreen, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
              color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: context.textHint, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
