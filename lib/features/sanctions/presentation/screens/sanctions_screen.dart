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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : Column(
                  key: const ValueKey('content'),
                  children: [
                    Expanded(
                      child: state.sanctions.isEmpty
                          ? Center(
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.verified_user_outlined, color: context.colors.primary, size: 56),
                                const SizedBox(height: AppSpacing.md),
                                Text('Sin amonestaciones', style: context.textTheme.bodyMedium),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Tu cuenta está en buen estado',
                                  style: TextStyle(color: context.textHint, fontSize: 12),
                                ),
                              ]),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              itemCount: state.sanctions.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
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
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl,
                      ),
                      child: OutlinedButton.icon(
                        onPressed: user == null ? null : () => _requestSupportCall(context, user.id),
                        icon: const Icon(Icons.support_agent_rounded, size: 18),
                        label: const Text('Solicitar llamada a soporte'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _requestSupportCall(BuildContext context, String userId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solicitar llamada a soporte'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Cuéntanos brevemente qué necesitas...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: context.colors.tertiaryContainer,
                borderRadius: AppRadius.pillR,
              ),
              child: Text(
                sanction.severity.displayName,
                style: TextStyle(
                  color: context.colors.onTertiaryContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${sanction.createdAt.day}/${sanction.createdAt.month}/${sanction.createdAt.year}',
              style: TextStyle(color: context.textHint, fontSize: 11),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(sanction.reason, style: context.textTheme.titleSmall),
          if (sanction.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(sanction.description!, style: context.textTheme.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (hasAppeal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: AppRadius.mdR,
              ),
              child: Row(children: [
                Icon(Icons.gavel_rounded, size: 14, color: context.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Apelación: ${sanction.appeals.first.status.displayName}',
                  style: context.textTheme.bodyMedium,
                ),
              ]),
            )
          else
            OutlinedButton(
              onPressed: () => _showAppealDialog(context),
              child: const Text('Apelar amonestación'),
            ),
        ]),
      ),
    );
  }

  void _showAppealDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apelar amonestación'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Explica por qué crees que esto fue un error...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
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
