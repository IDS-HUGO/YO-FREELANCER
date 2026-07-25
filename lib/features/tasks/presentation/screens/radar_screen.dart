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
        showAppSnackBar(context, next.error!, isError: true);
        ref.read(radarViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Radar'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.brandGreen,
          labelColor: AppTheme.brandGreen,
          unselectedLabelColor: context.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [Tab(text: 'Urgentes'), Tab(text: 'Tareas abiertas')],
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : TabBarView(controller: _tab, children: [
                _urgentList(state, user?.id),
                _openTaskList(state, user?.id),
              ]),
      ),
    );
  }

  Widget _urgentList(RadarState state, String? yoerId) {
    if (state.urgentTasks.isEmpty) {
      return const _EmptyRadar(text: 'Sin tareas urgentes cerca de ti');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: state.urgentTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final t = state.urgentTasks[i];
        final applied = state.hasAppliedToUrgent(t.id);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.flash_on_rounded, color: AppTheme.warningOrange, size: 18),
              const SizedBox(width: 6),
              Text('${t.category.emoji} ${t.category.displayName}',
                  style: const TextStyle(color: AppTheme.warningOrange, fontSize: 11, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (t.distanceKm != null)
                Text('${t.distanceKm!.toStringAsFixed(1)} km',
                    style: TextStyle(color: context.textHint, fontSize: 11)),
            ]),
            const SizedBox(height: 10),
            Text(t.title, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(t.description, style: TextStyle(color: context.textSecondary, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(children: [
              if (t.maxPrice != null)
                Text('Hasta \$${t.maxPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${t.applicantsCount} postulantes',
                  style: TextStyle(color: context.textHint, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: applied || yoerId == null
                    ? null
                    : () => ref.read(radarViewModelProvider.notifier).applyToUrgent(t.id, yoerId),
                child: Text(applied ? 'Ya te postulaste' : 'Postularme'),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _openTaskList(RadarState state, String? yoerId) {
    if (state.openTaskRequests.isEmpty) {
      return const _EmptyRadar(text: 'Sin tareas abiertas por el momento');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: state.openTaskRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final t = state.openTaskRequests[i];
        final applied = state.hasAppliedToTaskRequest(t.id);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.border, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${t.category.emoji} ${t.category.displayName}',
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: context.cardInner, borderRadius: BorderRadius.circular(8)),
                child: Text(t.mode.displayName, style: TextStyle(color: context.textSecondary, fontSize: 10)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(t.title, style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(t.description, style: TextStyle(color: context.textSecondary, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(children: [
              Text('\$${t.budget.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(t.serviceMode.displayName, style: TextStyle(color: context.textHint, fontSize: 11)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: applied || yoerId == null
                    ? null
                    : () => ref.read(radarViewModelProvider.notifier).applyToTaskRequest(t.id, yoerId),
                child: Text(applied ? 'Ya te postulaste' : 'Postularme'),
              ),
            ),
          ]),
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
        const SizedBox(height: 12),
        Text(text, style: TextStyle(color: context.textSecondary)),
      ]),
    );
  }
}
