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
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.brandGreen, size: 64),
            const SizedBox(height: 16),
            const Text('¡Pago exitoso!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('\$${_booking!.totalPrice.toStringAsFixed(2)} MXN',
                style: const TextStyle(color: AppTheme.brandGreen, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Método: ${_selectedMethod!.displayName}',
                style: TextStyle(color: AppTheme.textSecondaryDark)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandGreen,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.w700)),
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
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark, elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
        ),
        title: const Text('Realizar pago',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Resumen
            if (_booking != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.cardDark, AppTheme.cardInnerDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borderDark, width: 0.5),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('RESUMEN',
                      style: TextStyle(color: AppTheme.textHintDark, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Text(_booking!.serviceName,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('YOER: ${_booking!.yoerName}',
                      style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13)),
                  const Divider(color: AppTheme.borderDark, height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total a pagar',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    Text('\$${_booking!.totalPrice.toStringAsFixed(2)} MXN',
                        style: const TextStyle(color: AppTheme.brandGreen, fontSize: 20, fontWeight: FontWeight.w900)),
                  ]),
                ]),
              ),
              const SizedBox(height: 28),
            ],

            // Métodos de pago
            const Text('MÉTODO DE PAGO',
                style: TextStyle(color: AppTheme.textHintDark, fontSize: 11,
                    fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 14),
            ...PaymentMethodType.values.map((m) => _MethodCard(
              method: m,
              isSelected: _selectedMethod == m,
              onTap: () => setState(() => _selectedMethod = m),
            )),

            if (payState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.alertRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.alertRed.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: AppTheme.alertRedLight, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(payState.error!,
                      style: const TextStyle(color: AppTheme.alertRedLight, fontSize: 13))),
                ]),
              ),
            ],
          ]),
        )),

        // Botón de pago
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(top: BorderSide(color: AppTheme.borderDark, width: 0.5)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: (_selectedMethod == null || payState.isLoading) ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandGreen,
                  disabledBackgroundColor: AppTheme.borderDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: payState.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.lock_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _booking != null
                              ? 'Pagar \$${_booking!.totalPrice.toStringAsFixed(2)}'
                              : 'Pagar',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ]),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandGreen.withOpacity(0.1) : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.brandGreen : AppTheme.borderDark,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(children: [
          Text(method.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(method.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondaryDark,
                  fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                )),
            Text(_subtitle(method),
                style: TextStyle(color: AppTheme.textHintDark, fontSize: 11)),
          ])),
          if (isSelected)
            const Icon(Icons.check_circle_rounded, color: AppTheme.brandGreen, size: 22),
        ]),
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
