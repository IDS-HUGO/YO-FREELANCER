// lib/features/payments/presentation/screens/payment_methods_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/payment_remote_datasource.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(paymentViewModelProvider.notifier).loadCards(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(paymentViewModelProvider);

    ref.listen(paymentViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(paymentViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppSnackBar(context, next.error!, isError: true);
        ref.read(paymentViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Métodos de pago'),
        actions: [
          IconButton(
            onPressed: user == null ? null : () => _showAddCardSheet(context, user.id),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: state.cards.isEmpty
            ? Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.credit_card_outlined, color: context.textHint, size: 56),
                  const SizedBox(height: 12),
                  Text('Sin tarjetas guardadas', style: TextStyle(color: context.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: user == null ? null : () => _showAddCardSheet(context, user.id),
                    child: const Text('Agregar tarjeta'),
                  ),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: state.cards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final c = state.cards[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.greenGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(c.cardType.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                        const Spacer(),
                        if (c.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Predeterminada', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          onSelected: (v) {
                            if (v == 'default' && user != null) {
                              ref.read(paymentViewModelProvider.notifier).markDefaultCard(user.id, c.id);
                            } else if (v == 'delete' && user != null) {
                              ref.read(paymentViewModelProvider.notifier).deleteCard(c.id, user.id);
                            }
                          },
                          itemBuilder: (_) => [
                            if (!c.isDefault) const PopupMenuItem(value: 'default', child: Text('Usar como predeterminada')),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                          ],
                        ),
                      ]),
                      const SizedBox(height: 18),
                      Text(c.maskedNumber,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(c.cardHolderName.toUpperCase(),
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(c.expiryLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ]),
                  );
                },
              ),
      ),
    );
  }

  void _showAddCardSheet(BuildContext context, String userId) {
    final numberCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final monthCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    String cardType = 'VISA';
    bool asDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agregar tarjeta', style: TextStyle(color: ctx.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Solo guardamos los últimos 4 dígitos, nunca el número completo.',
                  style: TextStyle(color: ctx.textHint, fontSize: 11)),
              const SizedBox(height: 20),
              TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                maxLength: 16,
                style: TextStyle(color: ctx.textPrimary),
                decoration: const InputDecoration(labelText: 'Número de tarjeta', counterText: ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderCtrl,
                style: TextStyle(color: ctx.textPrimary),
                decoration: const InputDecoration(labelText: 'Nombre del titular'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: monthCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: ctx.textPrimary),
                    decoration: const InputDecoration(labelText: 'Mes (MM)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: yearCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: ctx.textPrimary),
                    decoration: const InputDecoration(labelText: 'Año (AAAA)'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: cardType,
                dropdownColor: ctx.card,
                style: TextStyle(color: ctx.textPrimary),
                decoration: const InputDecoration(labelText: 'Tipo de tarjeta'),
                items: const ['VISA', 'MASTERCARD', 'AMEX']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => cardType = v ?? cardType),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: asDefault,
                onChanged: (v) => setState(() => asDefault = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text('Usar como predeterminada', style: TextStyle(color: ctx.textSecondary, fontSize: 13)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final number = numberCtrl.text.trim();
                    final holder = holderCtrl.text.trim();
                    final month = int.tryParse(monthCtrl.text.trim());
                    final year = int.tryParse(yearCtrl.text.trim());
                    if (number.length < 4 || holder.isEmpty || month == null || year == null ||
                        month < 1 || month > 12) {
                      showAppSnackBar(context, 'Completa todos los campos correctamente', isError: true);
                      return;
                    }
                    Navigator.pop(ctx);
                    await ref.read(paymentViewModelProvider.notifier).addCard(
                          userId: userId,
                          cardNumber: number.substring(number.length - 4),
                          cardHolderName: holder,
                          expiryMonth: month,
                          expiryYear: year,
                          cardType: cardType,
                          isDefault: asDefault,
                        );
                  },
                  child: const Text('Guardar tarjeta'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
