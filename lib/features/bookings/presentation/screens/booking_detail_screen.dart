// lib/features/bookings/presentation/screens/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/booking_remote_datasource.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});
  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  BookingEntity? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ds = ref.read(bookingDataSourceProvider);
      final b = await ds.getBookingById(widget.bookingId);
      if (mounted) setState(() { _booking = b; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    Widget body;
    if (_loading) {
      body = const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
    } else if (_booking == null) {
      body = Center(
        key: const ValueKey('empty'),
        child: Text('Reserva no encontrada', style: context.textTheme.bodyMedium),
      );
    } else {
      final b          = _booking!;
      final isYoer     = user?.id == b.yoerId;
      final isClient   = user?.id == b.clientId;
      final dateStr    = DateFormat('dd/MM/yyyy').format(b.scheduledDateTime);
      final isPending   = b.status == BookingStatus.pendiente;
      final isConfirmed = b.status == BookingStatus.confirmada;

      body = SingleChildScrollView(
        key: const ValueKey('content'),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Estado + servicio
          Row(children: [
            Expanded(child: Text(b.serviceName,
                style: context.textTheme.headlineSmall,
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: AppSpacing.sm),
            BookingStatusChip(status: b.status.name),
          ]),
          const SizedBox(height: AppSpacing.xxl),

          // Tarjeta de precio
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              borderRadius: AppRadius.xlR,
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Total a pagar',
                    style: context.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                Text('\$${b.totalPrice.toStringAsFixed(2)} ${b.currency}',
                    style: context.textTheme.headlineMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.pillR,
                ),
                child: Text(b.paymentStatus == PaymentStatus.pagado ? 'PAGADO ✓' : 'PENDIENTE',
                    style: context.textTheme.labelSmall?.copyWith(color: Colors.white)),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Detalles
          _section('Detalles de la reserva', [
            _row(Icons.calendar_today_outlined, 'Fecha', dateStr),
            _row(Icons.access_time_rounded, 'Hora', b.scheduledTime),
            _row(Icons.timer_outlined, 'Duración', '${b.duration} min'),
            _row(Icons.location_on_outlined, 'Dirección', b.address),
            if (b.notes != null) _row(Icons.notes_rounded, 'Notas', b.notes!),
          ]),
          const SizedBox(height: AppSpacing.xl),

          // Partes involucradas
          _section('Personas', [
            _personRow(
              isYoer ? 'Cliente' : 'YOER',
              isYoer ? b.clientName : b.yoerName,
              isYoer ? b.clientImageUrl : b.yoerImageUrl,
              isYoer ? null : 'booking-avatar-${b.id}',
            ),
          ]),
          const SizedBox(height: AppSpacing.xxxl),

          // Acciones según rol y estado: un botón primario claro por estado,
          // con acciones secundarias/destructivas en Outlined.
          if (isYoer && isPending) ...[
            Row(children: [
              Expanded(child: FilledButton(
                onPressed: () => _action(() => ref.read(bookingViewModelProvider.notifier).confirmBooking(b.id)),
                child: const Text('Aceptar'),
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: OutlinedButton(
                onPressed: () => _cancelDialog(context, b.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.error,
                  side: BorderSide(color: context.colors.error),
                ),
                child: const Text('Rechazar'),
              )),
            ]),
          ],

          if (isYoer && isConfirmed) ...[
            FilledButton(
              onPressed: () => _action(() => ref.read(bookingViewModelProvider.notifier).startBooking(b.id)),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.infoBlue),
              child: const Text('Iniciar servicio'),
            ),
          ],

          if (isYoer && b.status == BookingStatus.enProgreso) ...[
            FilledButton(
              onPressed: () => _action(() => ref.read(bookingViewModelProvider.notifier).completeBooking(b.id)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_outlined),
                SizedBox(width: AppSpacing.sm),
                Text('Marcar como completado'),
              ]),
            ),
          ],

          if (isClient && b.status == BookingStatus.completada &&
              b.paymentStatus == PaymentStatus.pendiente) ...[
            FilledButton(
              onPressed: () async {
                await context.push('/payment/${b.id}');
                _load();
              },
              child: const Text('Realizar pago'),
            ),
          ],

          // El botón genérico de cancelar solo se muestra cuando no hay ya
          // una acción de rechazo equivalente arriba (YOER + pendiente).
          if ((isClient || isYoer) && (isPending || isConfirmed) && !(isYoer && isPending)) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => _cancelDialog(context, b.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.error,
                side: BorderSide(color: context.colors.error),
              ),
              child: const Text('Cancelar reserva'),
            ),
          ],
          const SizedBox(height: AppSpacing.huge),
        ]),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: _appBar(context),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: body,
      ),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
    leading: IconButton(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
    ),
    title: const Text('Detalle de reserva'),
  );

  Widget _section(String title, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.toUpperCase(),
          style: context.textTheme.labelMedium?.copyWith(letterSpacing: 1.2)),
      const SizedBox(height: AppSpacing.md),
      Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(children: rows),
      ),
    ],
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    child: Row(children: [
      Icon(icon, color: context.colors.onSurfaceVariant, size: 18),
      const SizedBox(width: AppSpacing.md),
      Text(label, style: context.textTheme.bodyMedium),
      const Spacer(),
      Flexible(child: Text(value,
          style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurface, fontWeight: FontWeight.w600),
          textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _personRow(String role, String name, String? imageUrl, String? heroTag) => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Row(children: [
      UserAvatar(
        imageUrl: imageUrl,
        initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
        size: 44,
        heroTag: heroTag,
      ),
      const SizedBox(width: AppSpacing.md),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(role, style: context.textTheme.labelSmall),
        Text(name, style: context.textTheme.titleSmall),
      ]),
    ]),
  );

  Future<void> _action(Future<bool> Function() action) async {
    final ok = await action();
    if (ok) {
      _load();
    } else if (mounted) {
      final err = ref.read(bookingViewModelProvider).error;
      showAppErrorDialog(context, title: 'No se pudo completar la acción', message: err ?? 'Intenta de nuevo más tarde.');
    }
  }

  void _cancelDialog(BuildContext context, String bookingId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Por qué deseas cancelar?', style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(hintText: 'Motivo...'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Atrás')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: context.colors.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(bookingViewModelProvider.notifier)
                  .cancelBooking(bookingId, reasonCtrl.text.isEmpty ? 'Sin motivo' : reasonCtrl.text);
              if (ok) {
                _load();
              } else if (context.mounted) {
                final err = ref.read(bookingViewModelProvider).error;
                showAppErrorDialog(context, title: 'No se pudo cancelar la reserva', message: err ?? 'Intenta de nuevo más tarde.');
              }
            },
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
  }
}
