// lib/features/volunteering/presentation/screens/volunteering_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/volunteering_remote_datasource.dart';

class VolunteeringScreen extends ConsumerStatefulWidget {
  const VolunteeringScreen({super.key});
  @override
  ConsumerState<VolunteeringScreen> createState() => _VolunteeringScreenState();
}

class _VolunteeringScreenState extends ConsumerState<VolunteeringScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(volunteeringViewModelProvider.notifier).load(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(volunteeringViewModelProvider);

    ref.listen(volunteeringViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(volunteeringViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppSnackBar(context, next.error!, isError: true);
        ref.read(volunteeringViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Voluntariado')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : state.events.isEmpty
                  ? Center(
                      key: const ValueKey('empty'),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.volunteer_activism_outlined, color: context.textHint, size: 56),
                        const SizedBox(height: AppSpacing.md),
                        Text('Sin voluntariados activos por ahora', style: context.textTheme.bodyMedium),
                      ]),
                    )
                  : ListView.separated(
                      key: const ValueKey('list'),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: state.events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
                      itemBuilder: (_, i) {
                        final e = state.events[i];
                        final joined = state.hasJoined(e.id);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(e.type.icon, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  e.type.displayName,
                                  style: TextStyle(
                                    color: context.colors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: AppSpacing.md),
                              Text(e.title, style: context.textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                e.description,
                                style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(children: [
                                Icon(Icons.calendar_today_outlined, size: 13, color: context.textHint),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  DateFormat('d MMM y', 'es').format(e.startsAt),
                                  style: TextStyle(color: context.textHint, fontSize: 11),
                                ),
                                if (e.address != null) ...[
                                  const SizedBox(width: AppSpacing.md),
                                  Icon(Icons.location_on_outlined, size: 13, color: context.textHint),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      e.address!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: context.textHint, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                width: double.infinity,
                                child: joined
                                    ? const FilledButton.tonal(
                                        onPressed: null,
                                        child: Text('¡Ya participas!'),
                                      )
                                    : FilledButton(
                                        onPressed: user == null
                                            ? null
                                            : () => ref.read(volunteeringViewModelProvider.notifier)
                                                .join(e.id, user.id),
                                        child: const Text('Quiero participar'),
                                      ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
