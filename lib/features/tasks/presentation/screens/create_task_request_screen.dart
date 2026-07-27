// lib/features/tasks/presentation/screens/create_task_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../services/domain/entities/service_entity.dart' show ServiceCategory;
import '../../data/datasources/task_remote_datasource.dart';
import '../viewmodels/client_tasks_viewmodel.dart';

class CreateTaskRequestScreen extends ConsumerStatefulWidget {
  const CreateTaskRequestScreen({super.key});
  @override
  ConsumerState<CreateTaskRequestScreen> createState() => _CreateTaskRequestScreenState();
}

class _CreateTaskRequestScreenState extends ConsumerState<CreateTaskRequestScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  ServiceCategory _category = ServiceCategory.otros;
  TaskMode _mode = TaskMode.expres;
  TaskServiceMode _serviceMode = TaskServiceMode.presencial;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _hoursCtrl.dispose();
    _budgetCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty || _budgetCtrl.text.trim().isEmpty) {
      showAppSnackBar(context, 'Completa qué necesitas y tu presupuesto', isError: true);
      return;
    }
    final budget = double.tryParse(_budgetCtrl.text.trim());
    if (budget == null) {
      showAppSnackBar(context, 'Ingresa un presupuesto válido', isError: true);
      return;
    }

    setState(() => _saving = true);
    final ok = await ref.read(clientTasksViewModelProvider.notifier).create(
          clientId: user.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          mode: _mode,
          serviceMode: _serviceMode,
          budget: budget,
          estimatedHours: double.tryParse(_hoursCtrl.text.trim()),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showAppSnackBar(context, '¡Tarea publicada! Los YOERs cercanos podrán postularse.');
      Navigator.of(context).pop();
    } else {
      final err = ref.read(clientTasksViewModelProvider).error;
      showAppErrorDialog(context, title: 'No se pudo publicar la tarea', message: err ?? 'Intenta de nuevo más tarde.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Crear tarea')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('¿Cómo la necesitas?', style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<TaskMode>(
              segments: const [
                ButtonSegment(value: TaskMode.expres, label: Text('Exprés (ahora)'), icon: Icon(Icons.bolt_rounded)),
                ButtonSegment(value: TaskMode.agendado, label: Text('Agendado'), icon: Icon(Icons.event_rounded)),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: AppSpacing.xxl),

            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Qué necesitas', hintText: 'Ej: Plomero para fuga de agua'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Descripción', alignLabelWithHint: true),
            ),
            const SizedBox(height: AppSpacing.lg),

            DropdownButtonFormField<ServiceCategory>(
              initialValue: _category,
              dropdownColor: context.card,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: ServiceCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.displayName}')))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: AppSpacing.lg),

            SegmentedButton<TaskServiceMode>(
              segments: TaskServiceMode.values
                  .map((m) => ButtonSegment(value: m, label: Text(m.displayName)))
                  .toList(),
              selected: {_serviceMode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _serviceMode = s.first),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(children: [
              Expanded(
                child: TextField(
                  controller: _hoursCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: 'Horas aprox.'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: 'Presupuesto (MXN)'),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _addressCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Domicilio (opcional)'),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _saving
                      ? const SizedBox(key: ValueKey('saving'), width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Publicar tarea', key: ValueKey('idle')),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
