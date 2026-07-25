// lib/features/tasks/presentation/screens/client_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../viewmodels/client_tasks_viewmodel.dart';
import 'create_task_request_screen.dart';
import 'task_request_detail_screen.dart';

class ClientTasksScreen extends ConsumerStatefulWidget {
  const ClientTasksScreen({super.key});
  @override
  ConsumerState<ClientTasksScreen> createState() => _ClientTasksScreenState();
}

class _ClientTasksScreenState extends ConsumerState<ClientTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(clientTasksViewModelProvider.notifier).load(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clientTasksViewModelProvider);

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, 0),
            child: Row(children: [
              Text('Mis Tareas', style: context.textTheme.headlineSmall),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateTaskRequestScreen())),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva'),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: state.isLoading
                  ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
                  : state.myTaskRequests.isEmpty
                      ? _empty(context)
                      : ListView.separated(
                          key: const ValueKey('list'),
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.xxxl),
                          itemCount: state.myTaskRequests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (_, i) {
                            final t = state.myTaskRequests[i];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => TaskRequestDetailScreen(task: t))),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(t.title,
                                          style: context.textTheme.titleSmall,
                                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      _StatusDot(status: t.status),
                                    ]),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text('${t.category.emoji} ${t.category.displayName} · ${t.mode.displayName}',
                                        style: context.textTheme.bodySmall),
                                    const SizedBox(height: AppSpacing.md),
                                    Text('\$${t.budget.toStringAsFixed(0)} ${t.currency}',
                                        style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      key: const ValueKey('empty'),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.assignment_outlined, color: context.textHint, size: 64),
        const SizedBox(height: AppSpacing.lg),
        Text('Sin tareas publicadas', style: context.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Publica lo que necesitas y los YOERs cercanos se postularán',
            textAlign: TextAlign.center, style: context.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateTaskRequestScreen())),
          child: const Text('Crear tarea'),
        ),
      ]),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final TaskRequestStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TaskRequestStatus.abierta => AppTheme.brandGreen,
      TaskRequestStatus.asignada => AppTheme.infoBlue,
      TaskRequestStatus.completada => AppTheme.brandGreen,
      TaskRequestStatus.cancelada => AppTheme.alertRedLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs / 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.pillR),
      child: Text(status.displayName, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
