// lib/features/sanctions/presentation/screens/sanctions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/sanction_viewmodel.dart';

class SanctionsScreen extends ConsumerStatefulWidget {
  const SanctionsScreen({super.key});
  @override
  ConsumerState<SanctionsScreen> createState() => _SanctionsScreenState();
}

class _SanctionsScreenState extends ConsumerState<SanctionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(sanctionViewModelProvider.notifier).load(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(sanctionViewModelProvider);

    ref.listen(sanctionViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(sanctionViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppSnackBar(context, next.error!, isError: true);
        ref.read(sanctionViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Amonestaciones')),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : Column(children: [
                Expanded(
                  child: state.sanctions.isEmpty
                      ? Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.verified_user_outlined, color: AppTheme.brandGreen, size: 56),
                            const SizedBox(height: 12),
                            Text('Sin amonestaciones', style: TextStyle(color: context.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Tu cuenta está en buen estado',
                                style: TextStyle(color: context.textHint, fontSize: 12)),
                          ]),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: state.sanctions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (_, i) => _SanctionCard(
                            sanction: state.sanctions[i],
                            onAppeal: (msg) => user == null
                                ? null
                                : ref.read(sanctionViewModelProvider.notifier)
                                    .appeal(state.sanctions[i].id, user.id, msg),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: OutlinedButton.icon(
                    onPressed: user == null ? null : () => _requestSupportCall(context, user.id),
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: const Text('Solicitar llamada a soporte'),
                  ),
                ),
              ]),
      ),
    );
  }

  void _requestSupportCall(BuildContext context, String userId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text('Solicitar llamada a soporte', style: TextStyle(color: context.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: TextStyle(color: context.textPrimary),
          decoration: const InputDecoration(hintText: 'Cuéntanos brevemente qué necesitas...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              ref.read(sanctionViewModelProvider.notifier)
                  .requestSupportCall(userId, 'Solicitud desde amonestaciones', message: ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

class _SanctionCard extends StatelessWidget {
  final SanctionEntity sanction;
  final void Function(String message)? onAppeal;
  const _SanctionCard({required this.sanction, required this.onAppeal});

  @override
  Widget build(BuildContext context) {
    final hasAppeal = sanction.appeals.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(sanction.severity.displayName,
                style: const TextStyle(color: AppTheme.warningOrange, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Text('${sanction.createdAt.day}/${sanction.createdAt.month}/${sanction.createdAt.year}',
              style: TextStyle(color: context.textHint, fontSize: 11)),
        ]),
        const SizedBox(height: 10),
        Text(sanction.reason, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
        if (sanction.description != null) ...[
          const SizedBox(height: 6),
          Text(sanction.description!, style: TextStyle(color: context.textSecondary, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        if (hasAppeal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.gavel_rounded, size: 14, color: context.textSecondary),
              const SizedBox(width: 8),
              Text('Apelación: ${sanction.appeals.first.status.displayName}',
                  style: TextStyle(color: context.textSecondary, fontSize: 12)),
            ]),
          )
        else
          OutlinedButton(
            onPressed: () => _showAppealDialog(context),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
            child: const Text('Apelar amonestación'),
          ),
      ]),
    );
  }

  void _showAppealDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text('Apelar amonestación', style: TextStyle(color: context.textPrimary)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: TextStyle(color: context.textPrimary),
          decoration: const InputDecoration(hintText: 'Explica por qué crees que esto fue un error...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) onAppeal?.call(ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Enviar apelación'),
          ),
        ],
      ),
    );
  }
}
