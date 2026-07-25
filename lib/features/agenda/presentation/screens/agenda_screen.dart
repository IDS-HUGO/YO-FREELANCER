// lib/features/agenda/presentation/screens/agenda_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../bookings/presentation/viewmodels/booking_viewmodel.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});
  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(bookingViewModelProvider.notifier).loadBookingsForYoer(user.id);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingViewModelProvider);

    ref.listen(bookingViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(bookingViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppSnackBar(context, next.error!, isError: true);
        ref.read(bookingViewModelProvider.notifier).clearMessages();
      }
    });

    final solicitudes = state.allBookings.where((b) => b.status == BookingStatus.pendiente).toList();
    final agenda = state.upcomingBookings.where((b) => b.status != BookingStatus.pendiente).toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Mi Agenda'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.brandGreen,
          labelColor: AppTheme.brandGreen,
          unselectedLabelColor: context.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: [
            Tab(text: 'Solicitudes${solicitudes.isNotEmpty ? ' (${solicitudes.length})' : ''}'),
            const Tab(text: 'Agenda'),
            const Tab(text: 'Historial'),
          ],
        ),
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : TabBarView(controller: _tab, children: [
                _SolicitudesTab(bookings: solicitudes),
                _AgendaTab(bookings: agenda),
                _HistorialTab(completed: state.completedBookings, cancelled: state.cancelledBookings),
              ]),
      ),
    );
  }
}

class _SolicitudesTab extends ConsumerWidget {
  final List<BookingEntity> bookings;
  const _SolicitudesTab({required this.bookings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) return const _EmptyState(icon: Icons.inbox_outlined, text: 'Sin solicitudes pendientes');
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = bookings[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Con ${b.clientName}', style: TextStyle(color: context.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${DateFormat('EEEE d MMM', 'es').format(b.scheduledDateTime)} · ${b.scheduledTime}',
                style: TextStyle(color: context.textHint, fontSize: 12)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(bookingViewModelProvider.notifier).cancelBooking(b.id, 'Rechazada por el YOER'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    foregroundColor: AppTheme.alertRedLight,
                    side: const BorderSide(color: AppTheme.alertRedLight),
                  ),
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(bookingViewModelProvider.notifier).confirmBooking(b.id),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                  child: const Text('Confirmar'),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

class _AgendaTab extends ConsumerWidget {
  final List<BookingEntity> bookings;
  const _AgendaTab({required this.bookings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) return const _EmptyState(icon: Icons.calendar_today_outlined, text: 'Sin trabajos agendados');

    final sorted = [...bookings]..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = sorted[i];
        return GestureDetector(
          onTap: () => context.push('/booking/${b.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 0.5),
            ),
            child: Row(children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: context.cardInner, borderRadius: BorderRadius.circular(12)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(DateFormat('d MMM', 'es').format(b.scheduledDateTime),
                      style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(b.scheduledTime, style: TextStyle(color: context.textHint, fontSize: 10)),
                ]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b.serviceName, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Con ${b.clientName}', style: TextStyle(color: context.textSecondary, fontSize: 11)),
                  const SizedBox(height: 6),
                  BookingStatusChip(status: b.status.name),
                ]),
              ),
              const SizedBox(width: 8),
              Column(children: [
                if (b.status == BookingStatus.confirmada)
                  _smallAction(context, ref, 'Iniciar', () => ref.read(bookingViewModelProvider.notifier).startBooking(b.id)),
                if (b.status == BookingStatus.enProgreso)
                  _smallAction(context, ref, 'Completar', () => ref.read(bookingViewModelProvider.notifier).completeBooking(b.id)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _smallAction(BuildContext context, WidgetRef ref, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppTheme.brandGreen, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _HistorialTab extends StatelessWidget {
  final List<BookingEntity> completed;
  final List<BookingEntity> cancelled;
  const _HistorialTab({required this.completed, required this.cancelled});

  @override
  Widget build(BuildContext context) {
    if (completed.isEmpty && cancelled.isEmpty) {
      return const _EmptyState(icon: Icons.history_rounded, text: 'Sin historial todavía');
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (completed.isNotEmpty) ...[
          Text('COMPLETADAS', style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 10),
          ...completed.map((b) => _historyTile(context, b)),
          const SizedBox(height: 20),
        ],
        if (cancelled.isNotEmpty) ...[
          Text('CANCELADAS / RECHAZADAS', style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 10),
          ...cancelled.map((b) => _historyTile(context, b)),
        ],
      ],
    );
  }

  Widget _historyTile(BuildContext context, BookingEntity b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            Text('Con ${b.clientName}', style: TextStyle(color: context.textSecondary, fontSize: 11)),
          ]),
        ),
        BookingStatusChip(status: b.status.name),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: context.textHint, size: 48),
        const SizedBox(height: 12),
        Text(text, style: TextStyle(color: context.textSecondary)),
      ]),
    );
  }
}
