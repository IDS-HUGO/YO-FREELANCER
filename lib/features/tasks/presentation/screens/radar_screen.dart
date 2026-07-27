// lib/features/tasks/presentation/screens/radar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/radar_viewmodel.dart';

class RadarScreen extends ConsumerStatefulWidget {
  const RadarScreen({super.key});
  @override
  ConsumerState<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends ConsumerState<RadarScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<Position?> _getPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final position = await _getPosition();
    ref.read(radarViewModelProvider.notifier).loadUrgentTasks(lat: position?.latitude, lng: position?.longitude);
    ref.read(radarViewModelProvider.notifier).loadOpenTaskRequests();
    ref.read(radarViewModelProvider.notifier).loadMyApplications(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(radarViewModelProvider);
    final user = ref.watch(currentUserProvider);

    ref.listen(radarViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(radarViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppErrorDialog(context, message: next.error!);
        ref.read(radarViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Radar'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: context.colors.primary,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [Tab(text: 'Urgentes'), Tab(text: 'Tareas abiertas')],
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : TabBarView(
                  key: const ValueKey('content'),
                  controller: _tab,
                  children: [
                    _urgentList(state, user?.id),
                    _openTaskList(state, user?.id),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _urgentList(RadarState state, String? yoerId) {
    if (state.urgentTasks.isEmpty) {
      return const _EmptyRadar(text: 'Sin tareas urgentes cerca de ti');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: state.urgentTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final t = state.urgentTasks[i];
        final applied = state.hasAppliedToUrgent(t.id);
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlR,
            side: BorderSide(color: AppTheme.warningOrange.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.flash_on_rounded, color: AppTheme.warningOrange, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text('${t.category.emoji} ${t.category.displayName}',
                    style: const TextStyle(color: AppTheme.warningOrange, fontSize: 11, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (t.distanceKm != null)
                  Text('${t.distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(color: context.textHint, fontSize: 11)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Text(t.title, style: context.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(t.description, style: context.textTheme.bodySmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                if (t.maxPrice != null)
                  Text('Hasta \$${t.maxPrice!.toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${t.applicantsCount} postulantes',
                    style: TextStyle(color: context.textHint, fontSize: 11)),
              ]),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: applied || yoerId == null
                      ? null
                      : () => ref.read(radarViewModelProvider.notifier).applyToUrgent(t.id, yoerId),
                  child: Text(applied ? 'Ya te postulaste' : 'Postularme'),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _openTaskList(RadarState state, String? yoerId) {
    if (state.openTaskRequests.isEmpty) {
      return const _EmptyRadar(text: 'Sin tareas abiertas por el momento');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: state.openTaskRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) {
        final t = state.openTaskRequests[i];
        final applied = state.hasAppliedToTaskRequest(t.id);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${t.category.emoji} ${t.category.displayName}',
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(color: context.cardInner, borderRadius: AppRadius.smR),
                  child: Text(t.mode.displayName, style: TextStyle(color: context.textSecondary, fontSize: 10)),
                ),
              ]),
              const SizedBox(height: AppSpacing.md),
              Text(t.title, style: context.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(t.description, style: context.textTheme.bodySmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Text('\$${t.budget.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text(t.serviceMode.displayName, style: TextStyle(color: context.textHint, fontSize: 11)),
              ]),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: applied || yoerId == null
                      ? null
                      : () => ref.read(radarViewModelProvider.notifier).applyToTaskRequest(t.id, yoerId),
                  child: Text(applied ? 'Ya te postulaste' : 'Postularme'),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _EmptyRadar extends StatelessWidget {
  final String text;
  const _EmptyRadar({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.radar_rounded, color: context.textHint, size: 56),
        const SizedBox(height: AppSpacing.md),
        Text(text, style: context.textTheme.bodyMedium),
      ]),
    );
  }
}
