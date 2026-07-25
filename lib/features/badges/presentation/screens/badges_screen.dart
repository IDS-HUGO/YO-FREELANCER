// lib/features/badges/presentation/screens/badges_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/badge_remote_datasource.dart';

class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});
  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(badgeViewModelProvider.notifier).load(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(badgeViewModelProvider);
    final progress = state.catalog.isEmpty ? 0.0 : state.earned.length / state.catalog.length;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Insignias')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : Padding(
                  key: const ValueKey('content'),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${state.earned.length} de ${state.catalog.length} desbloqueadas',
                        style: context.textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: AppRadius.pillR,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: context.card,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.lg,
                          crossAxisSpacing: AppSpacing.lg,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: state.catalog.length,
                        itemBuilder: (_, i) {
                          final badge = state.catalog[i];
                          final earned = state.isEarned(badge.code);
                          return Card(
                            color: earned ? context.colors.primaryContainer : context.card,
                            elevation: earned ? 2 : 1,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: earned ? 1 : 0.35,
                                  child: Text(badge.icon ?? '🏅', style: const TextStyle(fontSize: 36)),
                                ),
                                const SizedBox(height: AppSpacing.sm + 2),
                                Text(badge.name, textAlign: TextAlign.center,
                                    style: context.textTheme.titleSmall?.copyWith(
                                      color: earned ? context.textPrimary : context.textHint,
                                    )),
                                const SizedBox(height: AppSpacing.xs),
                                Text(badge.description ?? '', textAlign: TextAlign.center, maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.bodySmall?.copyWith(color: context.textHint)),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ]),
                ),
        ),
      ),
    );
  }
}
