// lib/features/yoer/presentation/screens/yoer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../bookings/data/datasources/booking_remote_datasource.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final user         = ref.watch(currentUserProvider);
    final bookingState = ref.watch(bookingViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
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
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Row(children: [
                    Container(width: 7, height: 7,
                        decoration: const BoxDecoration(color: AppTheme.brandGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Disponible', style: TextStyle(color: AppTheme.brandGreen, fontSize: 12)),
                  ]),
                ])),
                // Botones icono
                _iconBtn(Icons.notifications_outlined, () {}),
                const SizedBox(width: 8),
                _iconBtn(Icons.block_rounded, () {}, color: AppTheme.alertRed),
              ]),
              const SizedBox(height: 28),

              // ── Card disponibilidad ────────────────────────────────────
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: const BoxDecoration(color: AppTheme.brandGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  const Text('Disponible',
                      style: TextStyle(color: AppTheme.brandGreen, fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Text('CAMBIAR',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Bono semanal ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.cardDark, AppTheme.cardInnerDark],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark, width: 0.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text('Bono Sorpresa Semanal',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.brandGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('5 / 10 TAREAS',
                          style: TextStyle(color: AppTheme.brandGreen, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: 0.5,
                      minHeight: 8,
                      backgroundColor: Colors.black38,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.brandGreen),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('¡Te faltan 5 tareas para desbloquear el bono!',
                      style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 32),

              // ── Oportunidades ──────────────────────────────────────────
              SectionCard(
                title: 'Oportunidades en tiempo real',
                action: 'Abrir Radar',
                onAction: () {},
                child: _urgentCard(),
              ),
              const SizedBox(height: 32),

              // ── Próxima jornada ────────────────────────────────────────
              SectionCard(
                title: 'Próxima jornada',
                action: 'Mi agenda',
                onAction: () {},
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

  Widget _iconBtn(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          border: Border.all(
            color: color != null ? color.withOpacity(0.5) : AppTheme.borderDark,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20,
            color: color ?? AppTheme.textSecondaryDark),
      ),
    );
  }

  Widget _urgentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppTheme.cardInnerDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.flash_on_rounded, color: AppTheme.brandGreen, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TAREAS URGENTES',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text('3 servicios cancelados cerca de ti',
              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppTheme.textHintDark),
      ]),
    );
  }

  Widget _emptyBookings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark, width: 0.5),
      ),
      child: Column(children: [
        const Icon(Icons.calendar_today_outlined,
            color: AppTheme.textHintDark, size: 40),
        const SizedBox(height: 12),
        Text('Sin trabajos programados',
            style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 14)),
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
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppTheme.cardInnerDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(b.scheduledTime,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text('AM', style: TextStyle(color: AppTheme.textHintDark, fontSize: 9)),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName, style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Con ${b.clientName}',
                style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 11)),
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
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderDark, width: 0.5),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.brandGreen, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: AppTheme.textHintDark, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
