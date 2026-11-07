import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/config/payment_config.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../bookings/data/datasources/booking_remote_datasource.dart';
import '../../../legal/presentation/screens/legal_terms_screen.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethodType _selectedMethod = PaymentMethodType.tarjetaCredito;
  BookingEntity? _booking;
  bool _loading = true;
  bool _acceptedTerms = false;
  SandboxTestCard? _selectedTestCard = PaymentConfig.testCards.first;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final ds = ref.read(bookingDataSourceProvider);
      final b = await ds.getBookingById(widget.bookingId);
      if (mounted) setState(() { _booking = b; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pay() async {
    if (_booking == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor acepta los Términos y la Política de Pago en Garantía para continuar.'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
      return;
    }

    final ok = await ref.read(paymentViewModelProvider.notifier).processPayment(
      bookingId: _booking!.id,
      userId: user.id,
      amount: _booking!.totalPrice,
      paymentMethod: _selectedMethod,
      description: 'Pago de servicio: ${_booking!.serviceName}',
      yoerId: _booking!.yoerId,
      testCardNumber: _selectedMethod == PaymentMethodType.tarjetaCredito ? _selectedTestCard?.cardNumber : null,
    );

    if (!ok) {
      if (mounted) {
        final err = ref.read(paymentViewModelProvider).error;
        await showAppErrorDialog(
          context,
          title: 'No se pudo procesar el pago',
          message: err ?? 'Intenta de nuevo más tarde.',
        );
      }
      return;
    }

    if (mounted) {
      final breakdown = PaymentConfig.calculateBreakdown(_booking!.totalPrice);
      _showSuccessReceiptDialog(breakdown);
    }
  }

  void _showSuccessReceiptDialog(PaymentBreakdown breakdown) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlR),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppTheme.brandGreen, size: 56),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('¡Pago Procesado con Éxito!', style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.brandGreen.withValues(alpha: 0.2),
                borderRadius: AppRadius.pillR,
              ),
              child: const Text('MODO SANDBOX APROBADO', style: TextStyle(color: AppTheme.brandGreenDark, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              breakdown.formattedTotal,
              style: const TextStyle(color: AppTheme.brandGreen, fontSize: 26, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Servicio: ${_booking!.serviceName}', style: TextStyle(color: context.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            // Desglose de custodia en garantía
            _receiptRow('Monto total cargado:', breakdown.formattedTotal),
            _receiptRow('Comisión plataforma (${breakdown.feePercentLabel}):', breakdown.formattedFee, isSubtle: true),
            _receiptRow('Acreditación Yoer (en garantía):', breakdown.formattedYoerNet, isBold: true),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.textHint.withValues(alpha: 0.1),
                borderRadius: AppRadius.smR,
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, size: 14, color: AppTheme.brandGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Fondos resguardados en custodia hasta la finalización del servicio.',
                      style: context.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
                child: const Text('Entendido y Finalizar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isSubtle = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isSubtle ? context.textHint : context.textSecondary, fontSize: 12)),
          Text(value, style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: isBold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
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

    final breakdown = _booking != null ? PaymentConfig.calculateBreakdown(_booking!.totalPrice) : null;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Checkout & Pago Seguro'),
      ),
      body: Column(
        children: [
          // Banner de Sandbox Mode
          if (PaymentConfig.isSandbox)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B3D).withValues(alpha: 0.15),
                border: Border(bottom: BorderSide(color: const Color(0xFFFF6B3D).withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.developer_mode_rounded, color: Color(0xFFFF6B3D), size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Modo Sandbox Activo: Transacciones de prueba sin dinero real.',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFFF6B3D),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sello de Garantía Escrow
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.brandGreen.withValues(alpha: 0.12),
                          AppTheme.brandGreen.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: AppRadius.lgR,
                      border: Border.all(color: AppTheme.brandGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.brandGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: AppTheme.bgDark, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pago Protegido por YoFreelancer',
                                style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tu dinero queda en depósito de garantía. El Yoer solo cobra cuando tú confirmas el trabajo.',
                                style: context.textTheme.bodySmall?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Resumen financiero con desglose
                  if (_booking != null && breakdown != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'DESGLOSE DE SERVICIO',
                                  style: TextStyle(
                                    color: context.textHint,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandGreen.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Comisión plataforma: ${breakdown.feePercentLabel}',
                                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              _booking!.serviceName,
                              style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Proveedor (Yoer): ${_booking!.yoerName}', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                            Divider(color: context.border, height: AppSpacing.xl),

                            _receiptRow('Precio base acordado:', breakdown.formattedTotal),
                            _receiptRow('Comisión de plataforma retenida (${breakdown.feePercentLabel}):', breakdown.formattedFee, isSubtle: true),
                            _receiptRow('Acreditación neta al Yoer:', breakdown.formattedYoerNet, isSubtle: true),

                            Divider(color: context.border, height: AppSpacing.xl),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total a pagar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                Text(
                                  breakdown.formattedTotal,
                                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 22, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Métodos de pago
                  Text(
                    'SELECCIONA MÉTODO DE PAGO',
                    style: TextStyle(
                      color: context.textHint,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...PaymentMethodType.values.map((m) => _MethodCard(
                        method: m,
                        isSelected: _selectedMethod == m,
                        onTap: () => setState(() => _selectedMethod = m),
                      )),

                  // Tarjetas de prueba si seleccionó tarjeta en modo Sandbox
                  if (PaymentConfig.isSandbox &&
                      (_selectedMethod == PaymentMethodType.tarjetaCredito ||
                          _selectedMethod == PaymentMethodType.tarjetaDebito)) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'TARJETAS DE PRUEBA (SANDBOX STRIPE)',
                      style: TextStyle(
                        color: context.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...PaymentConfig.testCards.map((card) => _SandboxCardTile(
                          card: card,
                          isSelected: _selectedTestCard == card,
                          onTap: () => setState(() => _selectedTestCard = card),
                        )),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Aceptación de términos legales
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: AppRadius.mdR,
                      border: Border.all(color: context.border, width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                          activeColor: AppTheme.brandGreen,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LegalTermsScreen()),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: RichText(
                                text: TextSpan(
                                  style: context.textTheme.bodySmall?.copyWith(fontSize: 12),
                                  children: const [
                                    TextSpan(text: 'Acepto los '),
                                    TextSpan(
                                      text: 'Términos y Condiciones',
                                      style: TextStyle(
                                        color: AppTheme.brandGreen,
                                        fontWeight: FontWeight.w700,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: ', la custodia en Garantía Escrow y la comisión de intermediación del 10%.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Mensaje de error
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: payState.error == null
                        ? const SizedBox.shrink(key: ValueKey('no-error'))
                        : Padding(
                            key: const ValueKey('error'),
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: context.colors.error.withValues(alpha: 0.15),
                                borderRadius: AppRadius.mdR,
                                border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded, color: context.colors.error, size: 20),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      payState.error ?? '',
                                      style: TextStyle(color: context.colors.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Botón de pago fijado abajo
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
                  onPressed: payState.isLoading ? null : _pay,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: payState.isLoading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Row(
                            key: const ValueKey('idle'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _booking != null
                                    ? 'Confirmar Pago · \$${_booking!.totalPrice.toStringAsFixed(2)} MXN'
                                    : 'Confirmar Pago',
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SandboxCardTile extends StatelessWidget {
  final SandboxTestCard card;
  final bool isSelected;
  final VoidCallback onTap;

  const _SandboxCardTile({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? AppTheme.brandGreen.withValues(alpha: 0.12) : context.card,
        borderRadius: AppRadius.mdR,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdR,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mdR,
              border: Border.all(
                color: isSelected ? AppTheme.brandGreen : context.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  card.isSuccessful ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded,
                  color: card.isSuccessful ? AppTheme.brandGreen : AppTheme.alertRed,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${card.cardNumber} · Exp: ${card.expiryFormatted}',
                        style: TextStyle(color: context.textHint, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.radio_button_checked_rounded, color: AppTheme.brandGreen, size: 18)
                else
                  Icon(Icons.radio_button_off_rounded, color: context.textHint, size: 18),
              ],
            ),
          ),
        ),
      ),
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
            child: Row(
              children: [
                Text(method.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.displayName,
                        style: TextStyle(
                          color: isSelected ? context.textPrimary : context.textSecondary,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      Text(_subtitle(method), style: TextStyle(color: context.textHint, fontSize: 11)),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: context.colors.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(PaymentMethodType m) {
    switch (m) {
      case PaymentMethodType.efectivo:
        return 'Paga en efectivo al completar el servicio';
      case PaymentMethodType.tarjetaCredito:
        return 'Cargo protegido con tarjeta (Visa, MC, AMEX)';
      case PaymentMethodType.tarjetaDebito:
        return 'Cargo con tarjeta de débito bancaria';
      case PaymentMethodType.transferencia:
        return 'Transferencia directa SPEI vía CLABE STP';
      case PaymentMethodType.oxxo:
        return 'Genera código de barras para pagar en OXXO';
      case PaymentMethodType.paypal:
        return 'Paga seguro con tu cuenta de PayPal';
      case PaymentMethodType.mercadoPago:
        return 'Paga con saldo o cuotas en Mercado Pago';
    }
  }
}
