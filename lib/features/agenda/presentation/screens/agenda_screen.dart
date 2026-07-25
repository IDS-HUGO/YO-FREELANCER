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
          indicatorColor: context.colors.primary,
          labelColor: context.colors.primary,
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : TabBarView(
                  key: const ValueKey('content'),
                  controller: _tab,
                  children: [
                    _SolicitudesTab(bookings: solicitudes),
                    _AgendaTab(bookings: agenda),
                    _HistorialTab(completed: state.completedBookings, cancelled: state.cancelledBookings),
                  ],
                ),
        ),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final b = bookings[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.serviceName, style: context.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('Con ${b.clientName}', style: context.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Text('${DateFormat('EEEE d MMM', 'es').format(b.scheduledDateTime)} · ${b.scheduledTime}',
                  style: TextStyle(color: context.textHint, fontSize: 12)),
              const SizedBox(height: AppSpacing.md),
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
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => ref.read(bookingViewModelProvider.notifier).confirmBooking(b.id),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                    child: const Text('Confirmar'),
                  ),
                ),
              ]),
            ]),
          ),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final b = sorted[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/booking/${b.id}'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: context.cardInner, borderRadius: AppRadius.mdR),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat('d MMM', 'es').format(b.scheduledDateTime),
                        style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(b.scheduledTime, style: TextStyle(color: context.textHint, fontSize: 10)),
                  ]),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.serviceName, style: context.textTheme.titleSmall,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Con ${b.clientName}', style: context.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    BookingStatusChip(status: b.status.name),
                  ]),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (b.status == BookingStatus.confirmada)
                  _smallAction(context, ref, 'Iniciar', () => ref.read(bookingViewModelProvider.notifier).startBooking(b.id)),
                if (b.status == BookingStatus.enProgreso)
                  _smallAction(context, ref, 'Completar', () => ref.read(bookingViewModelProvider.notifier).completeBooking(b.id)),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _smallAction(BuildContext context, WidgetRef ref, String label, VoidCallback onTap) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        if (completed.isNotEmpty) ...[
          Text('COMPLETADAS', style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: AppSpacing.sm),
          ...completed.map((b) => _historyTile(context, b)),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (cancelled.isNotEmpty) ...[
          Text('CANCELADAS / RECHAZADAS', style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: AppSpacing.sm),
          ...cancelled.map((b) => _historyTile(context, b)),
        ],
      ],
    );
  }

  Widget _historyTile(BuildContext context, BookingEntity b) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.serviceName, style: context.textTheme.titleSmall),
                Text('Con ${b.clientName}', style: context.textTheme.bodySmall),
              ]),
            ),
            BookingStatusChip(status: b.status.name),
          ]),
        ),
      ),
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
        const SizedBox(height: AppSpacing.md),
        Text(text, style: context.textTheme.bodyMedium),
      ]),
    );
  }
}
