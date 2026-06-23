// lib/features/services/presentation/screens/service_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/service_viewmodel.dart';
import '../../../bookings/data/datasources/booking_remote_datasource.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});
  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceViewModelProvider.notifier).getServiceById(widget.serviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state   = ref.watch(serviceViewModelProvider);
    final service = state.selectedService;
    final user    = ref.watch(currentUserProvider);

    if (state.isLoading || service == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(slivers: [
        // AppBar con imagen
        SliverAppBar(
          backgroundColor: AppTheme.bgDark,
          expandedHeight: service.hasImages ? 260 : 100,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: service.hasImages
                ? Image.network(service.thumbnailUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.cardDark))
                : Container(
                    color: AppTheme.surfaceDark,
                    child: Center(child: Text(service.category.emoji, style: const TextStyle(fontSize: 64))),
                  ),
          ),
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Categoría
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${service.category.emoji} ${service.category.displayName}',
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              if (service.isPromoted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('⭐ DESTACADO',
                      style: TextStyle(color: AppTheme.warningOrange, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: 12),

            Text(service.title,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 16),

            // Precio + tipo
            Row(children: [
              Text(service.priceLabel,
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderDark, width: 0.5),
                ),
                child: Text(service.serviceType.displayName,
                    style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 20),

            // Rating y YOER
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderDark, width: 0.5),
              ),
              child: Row(children: [
                UserAvatar(imageUrl: service.yoerImageUrl, initials: service.yoerName[0].toUpperCase(), size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(service.yoerName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  Row(children: [
                    RatingStars(rating: service.rating),
                    const SizedBox(width: 6),
                    Text('${service.totalReviews} reseñas',
                        style: const TextStyle(color: AppTheme.textHintDark, fontSize: 11)),
                  ]),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textHintDark),
              ]),
            ),
            const SizedBox(height: 24),

            const Text('Descripción',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(service.description,
                style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 14, height: 1.6)),

            if (service.specialties.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Especialidades',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8,
                  children: service.specialties.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderDark, width: 0.5),
                    ),
                    child: Text(s, style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
                  )).toList()),
            ],

            if (service.includedItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('¿Qué incluye?',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ...service.includedItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.brandGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(item, style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13)),
                ]),
              )),
            ],
            const SizedBox(height: 100),
          ]),
        )),
      ]),

      // Botón de reservar (solo clientes)
      bottomNavigationBar: user?.isClient == true
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(top: BorderSide(color: AppTheme.borderDark, width: 0.5)),
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () => _showBookingSheet(context, service.id, service.title,
                      service.yoerId, service.price, user!.id),
                  child: const Text('Reservar Ahora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            )
          : null,
    );
  }

  void _showBookingSheet(BuildContext context, String serviceId, String serviceName,
      String yoerId, double price, String clientId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _BookingSheet(
        serviceId: serviceId,
        serviceName: serviceName,
        yoerId: yoerId,
        totalPrice: price,
        clientId: clientId,
      ),
    );
  }
}

// Mini sheet para crear reserva
class _BookingSheet extends ConsumerStatefulWidget {
  final String serviceId, serviceName, yoerId, clientId;
  final double totalPrice;
  const _BookingSheet({
    required this.serviceId, required this.serviceName,
    required this.yoerId, required this.clientId, required this.totalPrice,
  });

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  DateTime? _date;
  final String _time = '10:00';
  final _addressCtrl = TextEditingController();

  @override
  void dispose() { _addressCtrl.dispose(); super.dispose(); }

  Future<void> _confirm() async {
    if (_date == null || _addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos'), backgroundColor: AppTheme.warningOrange));
      return;
    }
    final ok = await ref.read(bookingViewModelProvider.notifier).createBooking(
      serviceId: widget.serviceId,
      yoerId: widget.yoerId,
      clientId: widget.clientId,
      serviceName: widget.serviceName,
      scheduledDate: _date!.millisecondsSinceEpoch,
      scheduledTime: _time,
      duration: 60,
      address: _addressCtrl.text.trim(),
      totalPrice: widget.totalPrice,
    );
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Reserva creada!'), backgroundColor: AppTheme.brandGreenDark));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Reservar servicio',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppTheme.textHintDark)),
          ]),
          const SizedBox(height: 20),
          Text(widget.serviceName, style: const TextStyle(color: AppTheme.textSecondaryDark)),
          const SizedBox(height: 4),
          Text('\$${widget.totalPrice.toStringAsFixed(0)} MXN',
              style: const TextStyle(color: AppTheme.brandGreen, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)));
              if (d != null) setState(() => _date = d);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark, width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondaryDark, size: 18),
                const SizedBox(width: 10),
                Text(_date == null ? 'Seleccionar fecha' : '${_date!.day}/${_date!.month}/${_date!.year}',
                    style: TextStyle(color: _date == null ? AppTheme.textHintDark : Colors.white)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Dirección del servicio',
              hintStyle: const TextStyle(color: AppTheme.textHintDark),
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.textSecondaryDark, size: 18),
              filled: true, fillColor: AppTheme.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderDark, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _confirm,
              child: const Text('Confirmar Reserva', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
