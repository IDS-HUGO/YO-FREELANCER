// lib/features/bookings/presentation/screens/booking_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/app_router.dart';
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
      final ds = BookingRemoteDataSource(
        ref.read(bookingDataSourceProvider)._client,
      );
      final b = await ds.getBookingById(widget.bookingId);
      if (mounted) setState(() { _booking = b; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: _appBar(context),
        body: Center(child: Text('Reserva no encontrada',
            style: TextStyle(color: AppTheme.textSecondaryDark))),
      );
    }

    final b        = _booking!;
    final isYoer   = user?.id == b.yoerId;
    final isClient = user?.id == b.clientId;
    final dateStr  = DateFormat('dd/MM/yyyy').format(b.scheduledDateTime);
    final isPending   = b.status == BookingStatus.pendiente;
    final isConfirmed = b.status == BookingStatus.confirmada;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: _appBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Estado + servicio
          Row(children: [
            Expanded(child: Text(b.serviceName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                maxLines: 2, overflow: TextOverflow.ellipsis)),
            BookingStatusChip(status: b.status.name),
          ]),
          const SizedBox(height: 24),

          // Tarjeta de precio
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.brandGreen, AppTheme.brandGreenDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total a pagar',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('\$${b.totalPrice.toStringAsFixed(2)} ${b.currency}',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(b.paymentStatus == PaymentStatus.pagado ? 'PAGADO ✓' : 'PENDIENTE',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Detalles
          _section('Detalles de la reserva', [
            _row(Icons.calendar_today_outlined, 'Fecha', dateStr),
            _row(Icons.access_time_rounded, 'Hora', b.scheduledTime),
            _row(Icons.timer_outlined, 'Duración', '${b.duration} min'),
            _row(Icons.location_on_outlined, 'Dirección', b.address),
            if (b.notes != null) _row(Icons.notes_rounded, 'Notas', b.notes!),
          ]),
          const SizedBox(height: 20),

          // Partes involucradas
          _section('Personas', [
            _personRow(isYoer ? 'Cliente' : 'YOER',
                isYoer ? b.clientName : b.yoerName,
                isYoer ? b.clientImageUrl : b.yoerImageUrl),
          ]),
          const SizedBox(height: 28),

          // Acciones según rol y estado
          if (isYoer && isPending) ...[
            Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: () => _action(() => ref.read(bookingViewModelProvider.notifier).confirmBooking(b.id)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Aceptar'),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton(
                onPressed: () => _cancelDialog(context, b.id),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.alertRedLight,
                    side: const BorderSide(color: AppTheme.alertRedLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Rechazar'),
              )),
            ]),
          ],

          if (isYoer && isConfirmed) ...[
            ElevatedButton(
              onPressed: () => _action(() => ref.read(bookingViewModelProvider.notifier).startBooking(b.id)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.infoBlue,
                  minimumSize: const Size(double.infinity, 50), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Iniciar servicio'),
            ),
          ],

          if (isYoer && b.status == BookingStatus.enProgreso) ...[
            ElevatedButton(
              onPressed: () => _action(() => ref.read(bookingViewModelProvider.notifier).completeBooking(b.id)),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen,
                  minimumSize: const Size(double.infinity, 50), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_outlined),
                SizedBox(width: 8),
                Text('Marcar como completado', style: TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ],

          if (isClient && b.status == BookingStatus.completada &&
              b.paymentStatus == PaymentStatus.pendiente) ...[
            ElevatedButton(
              onPressed: () => context.push('/payment/${b.id}'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.brandGreen,
                  minimumSize: const Size(double.infinity, 50), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Realizar pago', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ],

          if ((isClient || isYoer) && (isPending || isConfirmed)) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _cancelDialog(context, b.id),
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.alertRedLight,
                  side: const BorderSide(color: AppTheme.alertRedLight),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Cancelar reserva'),
            ),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
    backgroundColor: AppTheme.bgDark, elevation: 0,
    leading: IconButton(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
    ),
    title: const Text('Detalle de reserva',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
  );

  Widget _section(String title, List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title.toUpperCase(),
          style: const TextStyle(color: AppTheme.textHintDark, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderDark, width: 0.5),
        ),
        child: Column(children: rows),
      ),
    ],
  );

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(children: [
      Icon(icon, color: AppTheme.textSecondaryDark, size: 18),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13)),
      const Spacer(),
      Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _personRow(String role, String name, String? imageUrl) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      UserAvatar(imageUrl: imageUrl, initials: name.isNotEmpty ? name[0].toUpperCase() : '?', size: 44),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(role, style: TextStyle(color: AppTheme.textHintDark, fontSize: 11, letterSpacing: 0.5)),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    ]),
  );

  Future<void> _action(Future<bool> Function() action) async {
    final ok = await action();
    if (ok) _load();
  }

  void _cancelDialog(BuildContext context, String bookingId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar reserva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('¿Por qué deseas cancelar?', style: TextStyle(color: AppTheme.textSecondaryDark)),
          const SizedBox(height: 12),
          TextField(
            controller: reasonCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Motivo...',
              hintStyle: TextStyle(color: AppTheme.textHintDark),
              filled: true, fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Atrás', style: TextStyle(color: AppTheme.textSecondaryDark))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(bookingViewModelProvider.notifier)
                  .cancelBooking(bookingId, reasonCtrl.text.isEmpty ? 'Sin motivo' : reasonCtrl.text);
              if (ok) _load();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Cancelar reserva'),
          ),
        ],
      ),
    );
  }
}
