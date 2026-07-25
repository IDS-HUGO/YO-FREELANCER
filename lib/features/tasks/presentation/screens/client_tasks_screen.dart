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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(children: [
              Text('Mis Tareas', style: TextStyle(color: context.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateTaskRequestScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.brandGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Row(children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Nueva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                : state.myTaskRequests.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        itemCount: state.myTaskRequests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final t = state.myTaskRequests[i];
                          return GestureDetector(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TaskRequestDetailScreen(task: t))),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: context.border, width: 0.5),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(t.title,
                                      style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  _StatusDot(status: t.status),
                                ]),
                                const SizedBox(height: 6),
                                Text('${t.category.emoji} ${t.category.displayName} · ${t.mode.displayName}',
                                    style: TextStyle(color: context.textSecondary, fontSize: 12)),
                                const SizedBox(height: 10),
                                Text('\$${t.budget.toStringAsFixed(0)} ${t.currency}',
                                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
                              ]),
                            ),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.assignment_outlined, color: context.textHint, size: 64),
        const SizedBox(height: 16),
        Text('Sin tareas publicadas', style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Publica lo que necesitas y los YOERs cercanos se postularán',
            textAlign: TextAlign.center, style: TextStyle(color: context.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton(
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(status.displayName, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
