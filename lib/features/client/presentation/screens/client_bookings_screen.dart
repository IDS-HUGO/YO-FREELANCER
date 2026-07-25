import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../bookings/data/datasources/booking_remote_datasource.dart';

class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});
  @override
  ConsumerState<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(bookingViewModelProvider.notifier).loadBookingsForClient(user.id);
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingViewModelProvider);
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Completadas'),
            Tab(text: 'Canceladas'),
          ],
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : TabBarView(
                  key: const ValueKey('tabs'),
                  controller: _tab,
                  children: [
                    _BookingList(bookings: state.upcomingBookings),
                    _BookingList(bookings: state.completedBookings),
                    _BookingList(bookings: state.cancelledBookings),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, color: context.colors.outline, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('Sin reservas', style: context.textTheme.bodyMedium),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (ctx, i) {
        final b = bookings[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/booking/${b.id}'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        b.serviceName,
                        style: context.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    BookingStatusChip(status: b.status.name),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    UserAvatar(
                      imageUrl: b.yoerImageUrl,
                      initials: b.yoerName.isNotEmpty ? b.yoerName[0].toUpperCase() : '?',
                      size: 28,
                      heroTag: 'booking-avatar-${b.id}',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        b.yoerName,
                        style: context.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '\$${b.totalPrice.toStringAsFixed(0)}',
                      style: context.textTheme.titleSmall?.copyWith(color: context.colors.primary),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
