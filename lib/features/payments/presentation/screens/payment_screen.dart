// lib/features/payments/presentation/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../bookings/data/datasources/booking_remote_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethodType? _selectedMethod;
  BookingEntity? _booking;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final ds = ref.read(bookingDataSourceProvider);
      final b  = await ds.getBookingById(widget.bookingId);
      if (mounted) setState(() { _booking = b; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pay() async {
    if (_selectedMethod == null || _booking == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final ok = await ref.read(paymentViewModelProvider.notifier).processPayment(
      bookingId: _booking!.id,
      userId: user.id,
      amount: _booking!.totalPrice,
      paymentMethod: _selectedMethod!,
      description: 'Pago: ${_booking!.serviceName}',
    );

    if (ok && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_rounded, color: context.colors.primary, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text('¡Pago exitoso!', style: context.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('\$${_booking!.totalPrice.toStringAsFixed(2)} MXN',
                style: TextStyle(color: context.colors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: AppSpacing.sm),
            Text('Método: ${_selectedMethod!.displayName}',
                style: TextStyle(color: context.textSecondary)),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('Listo'),
              ),
            ),
          ]),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payState = ref.watch(paymentViewModelProvider);

    if (_loading) {
      return Scaffold(
        backgroundColor: context.bg,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
      );
    }

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Realizar pago'),
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Resumen
            if (_booking != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('RESUMEN',
                        style: TextStyle(color: context.textHint, fontSize: 11,
                            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                    const SizedBox(height: AppSpacing.md),
                    Text(_booking!.serviceName,
                        style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text('YOER: ${_booking!.yoerName}',
                        style: TextStyle(color: context.textSecondary, fontSize: 13)),
                    Divider(color: context.border, height: AppSpacing.xxl),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Total a pagar',
                          style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('\$${_booking!.totalPrice.toStringAsFixed(2)} MXN',
                          style: TextStyle(color: context.colors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl + 4),
            ],

            // Métodos de pago
            Text('MÉTODO DE PAGO',
                style: TextStyle(color: context.textHint, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: AppSpacing.md + 2),
            ...PaymentMethodType.values.map((m) => _MethodCard(
              method: m,
              isSelected: _selectedMethod == m,
              onTap: () => setState(() => _selectedMethod = m),
            )),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: payState.error == null
                  ? const SizedBox.shrink(key: ValueKey('no-error'))
                  : Padding(
                      key: const ValueKey('error'),
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md + 2),
                        decoration: BoxDecoration(
                          color: context.colors.error.withValues(alpha: 0.15),
                          borderRadius: AppRadius.mdR,
                          border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline_rounded, color: context.colors.error, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(payState.error ?? '',
                              style: TextStyle(color: context.colors.error, fontSize: 13))),
                        ]),
                      ),
                    ),
            ),
          ]),
        )),

        // Botón de pago
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: context.card,
            border: Border(top: BorderSide(color: context.border, width: 0.5)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_selectedMethod == null || payState.isLoading) ? null : _pay,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: payState.isLoading
                      ? const SizedBox(key: ValueKey('loading'), width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : Row(key: const ValueKey('idle'), mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.lock_rounded, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _booking != null
                                ? 'Pagar \$${_booking!.totalPrice.toStringAsFixed(2)}'
                                : 'Pagar',
                          ),
                        ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final PaymentMethodType method;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodCard({required this.method, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: Material(
        color: isSelected ? context.colors.primary.withValues(alpha: 0.1) : context.card,
        borderRadius: AppRadius.lgR,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgR,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgR,
              border: Border.all(
                color: isSelected ? context.colors.primary : context.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(children: [
              Text(method.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(method.displayName,
                    style: TextStyle(
                      color: isSelected ? context.textPrimary : context.textSecondary,
                      fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    )),
                Text(_subtitle(method),
                    style: TextStyle(color: context.textHint, fontSize: 11)),
              ])),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: context.colors.primary, size: 22),
            ]),
          ),
        ),
      ),
    );
  }

  String _subtitle(PaymentMethodType m) {
    switch (m) {
      case PaymentMethodType.efectivo:       return 'Paga al completar el servicio';
      case PaymentMethodType.tarjetaCredito: return 'Cargo inmediato a tu tarjeta';
      case PaymentMethodType.tarjetaDebito:  return 'Cargo inmediato a tu cuenta';
      case PaymentMethodType.transferencia:  return 'Transferencia bancaria directa';
      case PaymentMethodType.oxxo:           return 'Genera un código para OXXO';
      case PaymentMethodType.paypal:         return 'Paga con tu cuenta PayPal';
      case PaymentMethodType.mercadoPago:    return 'Paga con Mercado Pago';
    }
  }
}
