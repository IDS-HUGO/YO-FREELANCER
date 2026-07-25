// lib/features/wallet/presentation/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/wallet_viewmodel.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});
  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(walletViewModelProvider.notifier).load(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(walletViewModelProvider);

    ref.listen(walletViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(walletViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppSnackBar(context, next.error!, isError: true);
        ref.read(walletViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('YOER Cash')),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : RefreshIndicator(
                onRefresh: () async => user != null ? ref.read(walletViewModelProvider.notifier).load(user.id) : null,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppTheme.greenGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Saldo disponible',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('\$${(state.account?.balance ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                        if ((state.account?.pendingBalance ?? 0) > 0) ...[
                          const SizedBox(height: 6),
                          Text('\$${state.account!.pendingBalance.toStringAsFixed(2)} pendiente',
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: user == null ? null : () => _showWithdrawDialog(context, user.id),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.brandGreenDark),
                            child: const Text('Retirar / Transferir'),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    if (state.pending.isNotEmpty) ...[
                      Text('DEPÓSITOS Y RETIROS PENDIENTES',
                          style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      ...state.pending.map(_transactionTile),
                      const SizedBox(height: 24),
                    ],

                    Text('HISTORIAL',
                        style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    if (state.transactions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Sin movimientos todavía', style: TextStyle(color: context.textSecondary))),
                      )
                    else
                      ...state.transactions.map(_transactionTile),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _transactionTile(WalletTransactionEntity t) {
    final color = t.type.isCredit ? AppTheme.brandGreen : AppTheme.alertRedLight;
    final sign = t.type.isCredit ? '+' : '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Row(children: [
        Text(t.type.icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.description ?? t.type.displayName,
                style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${DateFormat('d MMM, HH:mm', 'es').format(t.createdAt)} · ${t.status.displayName}',
              style: TextStyle(color: context.textHint, fontSize: 11),
            ),
          ]),
        ),
        Text('$sign\$${t.amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  void _showWithdrawDialog(BuildContext context, String userId) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text('Retirar / Transferir', style: TextStyle(color: context.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: context.textPrimary),
            decoration: const InputDecoration(labelText: 'Monto a retirar (MXN)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            style: TextStyle(color: context.textPrimary),
            decoration: const InputDecoration(labelText: 'Cuenta / referencia (opcional)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text.trim());
              Navigator.pop(ctx);
              if (amount == null || amount <= 0) {
                showAppSnackBar(context, 'Ingresa un monto válido', isError: true);
                return;
              }
              ref.read(walletViewModelProvider.notifier).requestWithdrawal(
                    userId, amount,
                    description: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                  );
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }
}
