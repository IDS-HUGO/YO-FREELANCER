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
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Text('Mis Reservas',
                style: TextStyle(color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tab,
            indicatorColor: AppTheme.brandGreen,
            labelColor: AppTheme.brandGreen,
            unselectedLabelColor: context.textHint,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [Tab(text: 'Próximas'), Tab(text: 'Completadas'), Tab(text: 'Canceladas')],
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                : TabBarView(controller: _tab, children: [
                    _BookingList(bookings: state.upcomingBookings),
                    _BookingList(bookings: state.completedBookings),
                    _BookingList(bookings: state.cancelledBookings),
                  ]),
          ),
        ]),
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
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.calendar_today_outlined, color: context.textHint, size: 48),
        const SizedBox(height: 12),
        Text('Sin reservas', style: TextStyle(color: context.textSecondary)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final b = bookings[i];
        return GestureDetector(
          onTap: () => context.push('/booking/${b.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(b.serviceName,
                    style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                BookingStatusChip(status: b.status.name),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.person_outline_rounded, size: 14, color: context.textHint),
                const SizedBox(width: 4),
                Text(b.yoerName, style: TextStyle(color: context.textSecondary, fontSize: 12)),
                const Spacer(),
                Text('\$${b.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
