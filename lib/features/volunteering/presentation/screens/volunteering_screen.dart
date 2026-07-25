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
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : state.events.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.volunteer_activism_outlined, color: context.textHint, size: 56),
                      const SizedBox(height: 12),
                      Text('Sin voluntariados activos por ahora', style: TextStyle(color: context.textSecondary)),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final e = state.events[i];
                      final joined = state.hasJoined(e.id);
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppTheme.cardGradient(context.isDark),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.border, width: 0.5),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(e.type.icon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(e.type.displayName,
                                style: const TextStyle(color: AppTheme.brandGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 10),
                          Text(e.title, style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(e.description, style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 12),
                          Row(children: [
                            Icon(Icons.calendar_today_outlined, size: 13, color: context.textHint),
                            const SizedBox(width: 6),
                            Text(DateFormat('d MMM y', 'es').format(e.startsAt),
                                style: TextStyle(color: context.textHint, fontSize: 11)),
                            if (e.address != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.location_on_outlined, size: 13, color: context.textHint),
                              const SizedBox(width: 4),
                              Expanded(child: Text(e.address!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: context.textHint, fontSize: 11))),
                            ],
                          ]),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: joined || user == null
                                  ? null
                                  : () => ref.read(volunteeringViewModelProvider.notifier).join(e.id, user.id),
                              child: Text(joined ? '¡Ya participas!' : 'Quiero participar'),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    );
  }
}
