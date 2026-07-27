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
        showAppErrorDialog(context, message: next.error!);
        ref.read(walletViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('YOER Cash')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : RefreshIndicator(
                  key: const ValueKey('content'),
                  onRefresh: () async => user != null ? ref.read(walletViewModelProvider.notifier).load(user.id) : null,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      _BalanceCard(
                        balance: state.account?.balance ?? 0,
                        pendingBalance: state.account?.pendingBalance ?? 0,
                        onWithdraw: user == null ? null : () => _showWithdrawDialog(context, user.id),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      if (state.pending.isNotEmpty) ...[
                        Text('DEPÓSITOS Y RETIROS PENDIENTES',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: context.textHint, fontWeight: FontWeight.w800, letterSpacing: 1,
                            )),
                        const SizedBox(height: AppSpacing.md),
                        ...state.pending.map((t) => _transactionTile(context, t)),
                        const SizedBox(height: AppSpacing.xxl),
                      ],

                      Text('HISTORIAL',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.textHint, fontWeight: FontWeight.w800, letterSpacing: 1,
                          )),
                      const SizedBox(height: AppSpacing.md),
                      if (state.transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                          child: Center(
                            child: Text('Sin movimientos todavía', style: context.textTheme.bodyMedium),
                          ),
                        )
                      else
                        ...state.transactions.map((t) => _transactionTile(context, t)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _transactionTile(BuildContext context, WalletTransactionEntity t) {
    final color = t.type.isCredit ? context.colors.primary : context.colors.error;
    final sign = t.type.isCredit ? '+' : '-';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(children: [
          Text(t.type.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.description ?? t.type.displayName,
                  style: context.textTheme.titleSmall,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                '${DateFormat('d MMM, HH:mm', 'es').format(t.createdAt)} · ${t.status.displayName}',
                style: context.textTheme.bodySmall?.copyWith(color: context.textHint),
              ),
            ]),
          ),
          Text('$sign\$${t.amount.toStringAsFixed(2)}',
              style: context.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, String userId) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirar / Transferir'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto a retirar (MXN)'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Cuenta / referencia (opcional)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
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

/// Tarjeta de saldo con acento de marca (gradiente verde) y acción principal.
class _BalanceCard extends StatelessWidget {
  final double balance;
  final double pendingBalance;
  final VoidCallback? onWithdraw;

  const _BalanceCard({
    required this.balance,
    required this.pendingBalance,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: AppTheme.brandGreen.withValues(alpha: 0.4),
      borderRadius: AppRadius.xlR,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: const BoxDecoration(gradient: AppTheme.greenGradient),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Saldo disponible',
              style: context.textTheme.labelLarge?.copyWith(
                color: Colors.white70, fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: AppSpacing.sm),
          Text('\$${balance.toStringAsFixed(2)}',
              style: context.textTheme.headlineLarge?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800,
              )),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: pendingBalance > 0
                ? Padding(
                    key: const ValueKey('pending'),
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text('\$${pendingBalance.toStringAsFixed(2)} pendiente',
                        style: context.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                  )
                : const SizedBox.shrink(key: ValueKey('no-pending')),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onWithdraw,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.brandGreenDark,
              ),
              child: const Text('Retirar / Transferir'),
            ),
          ),
        ]),
      ),
    );
  }
}
