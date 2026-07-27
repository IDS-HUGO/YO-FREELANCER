// lib/features/tasks/presentation/screens/task_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/task_remote_datasource.dart';
import '../viewmodels/client_tasks_viewmodel.dart';

class TaskRequestDetailScreen extends ConsumerStatefulWidget {
  final TaskRequestEntity task;
  const TaskRequestDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskRequestDetailScreen> createState() => _TaskRequestDetailScreenState();
}

class _TaskRequestDetailScreenState extends ConsumerState<TaskRequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clientTasksViewModelProvider.notifier).loadApplications(widget.task.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(clientTasksViewModelProvider);
    final applications = state.applicationsByTaskId[widget.task.id] ?? [];
    final task = state.myTaskRequests.firstWhere((t) => t.id == widget.task.id, orElse: () => widget.task);

    ref.listen(clientTasksViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(clientTasksViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppErrorDialog(context, message: next.error!);
        ref.read(clientTasksViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Detalle de tarea')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            Row(children: [
              Text('${task.category.emoji} ${task.category.displayName}',
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 12, fontWeight: FontWeight.w700)),
              const Spacer(),
              _StatusChip(status: task.status),
            ]),
            const SizedBox(height: AppSpacing.md),
            Text(task.title, style: context.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(task.description, style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              Text('\$${task.budget.toStringAsFixed(0)} ${task.currency}',
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.md),
              Text(task.serviceMode.displayName, style: TextStyle(color: context.textHint, fontSize: 12)),
            ]),

            if (task.status == TaskRequestStatus.abierta && user != null) ...[
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                onPressed: () => ref.read(clientTasksViewModelProvider.notifier).cancel(task.id, user.id),
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.alertRedLight, side: const BorderSide(color: AppTheme.alertRedLight)),
                child: const Text('Cancelar tarea'),
              ),
            ],
            if (task.status == TaskRequestStatus.asignada && user != null) ...[
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => ref.read(clientTasksViewModelProvider.notifier).complete(task.id, user.id),
                child: const Text('Marcar como completada'),
              ),
            ],

            const SizedBox(height: AppSpacing.xxxl - AppSpacing.xs),
            Divider(color: context.border),
            const SizedBox(height: AppSpacing.lg),
            Text('POSTULACIONES (${applications.length})',
                style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: AppSpacing.lg),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: applications.isEmpty
                  ? Padding(
                      key: const ValueKey('empty'),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(child: Text('Sin postulaciones todavía', style: context.textTheme.bodyMedium)),
                    )
                  : Column(
                      key: const ValueKey('list'),
                      children: applications.map((app) => _ApplicationCard(
                            app: app,
                            canAct: task.status == TaskRequestStatus.abierta,
                            onAccept: user == null ? null : () => ref.read(clientTasksViewModelProvider.notifier).acceptApplication(app, user.id),
                            onReject: () => ref.read(clientTasksViewModelProvider.notifier).rejectApplication(app.id, task.id),
                          )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final TaskApplicationEntity app;
  final bool canAct;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const _ApplicationCard({required this.app, required this.canAct, this.onAccept, this.onReject});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              UserAvatar(imageUrl: app.yoerImageUrl, initials: (app.yoerName?.isNotEmpty ?? false) ? app.yoerName![0].toUpperCase() : '?', size: 36),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.yoerName ?? 'YOER', style: context.textTheme.titleSmall),
                  if (app.yoerRating != null) RatingStars(rating: app.yoerRating!, size: 12),
                ]),
              ),
              _AppStatusChip(status: app.status),
            ]),
            if (app.proposal != null && app.proposal!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(app.proposal!, style: context.textTheme.bodySmall),
            ],
            if (canAct && app.status == ApplicationStatus.pendiente) ...[
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(38), foregroundColor: AppTheme.alertRedLight,
                        side: const BorderSide(color: AppTheme.alertRedLight)),
                    child: const Text('Rechazar', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(38)),
                    child: const Text('Aceptar', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TaskRequestStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TaskRequestStatus.abierta => AppTheme.brandGreen,
      TaskRequestStatus.asignada => AppTheme.infoBlue,
      TaskRequestStatus.completada => AppTheme.brandGreen,
      TaskRequestStatus.cancelada => AppTheme.alertRedLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.pillR),
      child: Text(status.displayName, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _AppStatusChip extends StatelessWidget {
  final ApplicationStatus status;
  const _AppStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ApplicationStatus.pendiente => AppTheme.warningOrange,
      ApplicationStatus.aceptada => AppTheme.brandGreen,
      ApplicationStatus.rechazada => AppTheme.alertRedLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppRadius.pillR),
      child: Text(status.displayName, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
