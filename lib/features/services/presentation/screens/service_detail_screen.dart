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
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      body: CustomScrollView(slivers: [
        // AppBar con imagen
        SliverAppBar(
          backgroundColor: context.bg,
          expandedHeight: service.hasImages ? 260 : 100,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: service.hasImages
                ? Image.network(service.thumbnailUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: context.card))
                : Container(
                    color: context.card,
                    child: Center(child: Text(service.category.emoji, style: const TextStyle(fontSize: 64))),
                  ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Categoría
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillR,
                ),
                child: Text('${service.category.emoji} ${service.category.displayName}',
                    style: context.textTheme.labelSmall?.copyWith(
                        color: context.colors.primary, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              if (service.isPromoted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.colors.tertiary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillR,
                  ),
                  child: Text('⭐ DESTACADO',
                      style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.tertiary, fontWeight: FontWeight.w700)),
                ),
            ]),
            const SizedBox(height: AppSpacing.md),

            Text(service.title,
                style: context.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: AppSpacing.lg),

            // Precio + tipo
            Row(children: [
              Text(service.priceLabel,
                  style: TextStyle(color: context.colors.primary, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: AppRadius.mdR,
                  border: Border.all(color: context.border, width: 0.5),
                ),
                child: Text(service.serviceType.displayName,
                    style: context.textTheme.labelMedium?.copyWith(color: context.textSecondary)),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),

            // Rating y YOER
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(children: [
                  UserAvatar(imageUrl: service.yoerImageUrl, initials: service.yoerName[0].toUpperCase(), size: 44),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(service.yoerName,
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Row(children: [
                      RatingStars(rating: service.rating),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Text('${service.totalReviews} reseñas',
                          style: TextStyle(color: context.textHint, fontSize: 11)),
                    ]),
                  ])),
                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: context.textHint),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text('Descripción',
                style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(service.description,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.6)),

            if (service.specialties.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('Especialidades',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm + 2),
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm,
                  children: service.specialties
                      .map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact))
                      .toList()),
            ],

            if (service.includedItems.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text('¿Qué incluye?',
                  style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm + 2),
              ...service.includedItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded, color: context.colors.primary, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: context.textTheme.bodySmall)),
                ]),
              )),
            ],
            const SizedBox(height: AppSpacing.huge + AppSpacing.xxxl + AppSpacing.xl),
          ]),
        )),
      ]),

      // Botón de reservar (solo clientes)
      bottomNavigationBar: user?.isClient == true
          ? Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: context.card,
                border: Border(top: BorderSide(color: context.border, width: 0.5)),
              ),
              child: SafeArea(
                child: FilledButton(
                  onPressed: () => _showBookingSheet(context, service.id, service.title,
                      service.yoerId, service.price, user!.id),
                  child: const Text('Reservar Ahora'),
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
      backgroundColor: context.card,
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
      showAppSnackBar(context, 'Completa todos los campos', isError: true);
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
      showAppSnackBar(context, '¡Reserva creada!');
    } else if (mounted) {
      final err = ref.read(bookingViewModelProvider).error;
      showAppErrorDialog(context, title: 'No se pudo crear la reserva', message: err ?? 'Intenta de nuevo más tarde.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Reservar servicio', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close_rounded, color: context.textHint)),
          ]),
          const SizedBox(height: AppSpacing.xl),
          Text(widget.serviceName, style: context.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('\$${widget.totalPrice.toStringAsFixed(0)} MXN',
              style: TextStyle(color: context.colors.primary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xl),
          Material(
            color: context.card,
            borderRadius: AppRadius.lgR,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: AppRadius.lgR,
              onTap: () async {
                final d = await showDatePicker(context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)));
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.lgR,
                  border: Border.all(color: context.border, width: 0.5),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, color: context.textSecondary, size: 18),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Text(_date == null ? 'Seleccionar fecha' : '${_date!.day}/${_date!.month}/${_date!.year}',
                      style: TextStyle(color: _date == null ? context.textHint : context.textPrimary)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _addressCtrl,
            style: TextStyle(color: context.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Dirección del servicio',
              prefixIcon: Icon(Icons.location_on_outlined, size: 18),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _confirm,
              child: const Text('Confirmar Reserva'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ]),
      ),
    );
  }
}
