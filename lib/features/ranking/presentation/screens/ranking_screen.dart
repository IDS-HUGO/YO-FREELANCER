// lib/features/ranking/presentation/screens/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/ranking_remote_datasource.dart';

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});
  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(rankingViewModelProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rankingViewModelProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Ranking de YOERs')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0,
            ),
            child: SegmentedButton<RankingMetric>(
              segments: RankingMetric.values
                  .map((m) => ButtonSegment(value: m, label: Text(m.displayName)))
                  .toList(),
              selected: {state.metric},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  ref.read(rankingViewModelProvider.notifier).load(metric: selection.first),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.isLoading
                  ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
                  : state.entries.isEmpty
                      ? Center(
                          key: const ValueKey('empty'),
                          child: Text('Sin datos suficientes todavía', style: context.textTheme.bodyMedium),
                        )
                      : ListView.separated(
                          key: const ValueKey('content'),
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          itemCount: state.entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm + 2),
                          itemBuilder: (_, i) {
                            final e = state.entries[i];
                            final isTop3 = i < 3;
                            final isMe = currentUser != null && e.id == currentUser.id;
                            return Card(
                              color: isMe ? context.colors.primaryContainer : context.card,
                              elevation: isTop3 || isMe ? 2 : 1,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text('${i + 1}',
                                        style: context.textTheme.titleMedium?.copyWith(
                                          color: isTop3 ? context.colors.primary : context.textHint,
                                          fontWeight: FontWeight.w800,
                                        )),
                                  ),
                                  UserAvatar(
                                    imageUrl: e.profileImageUrl,
                                    initials: e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : '?',
                                    size: 42,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(e.fullName, style: context.textTheme.titleSmall),
                                      if (e.city != null)
                                        Text(e.city!, style: context.textTheme.bodySmall?.copyWith(color: context.textHint)),
                                    ]),
                                  ),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    RatingStars(rating: e.rating, size: 13),
                                    const SizedBox(height: 2),
                                    Text('${e.completedJobs} tareas',
                                        style: context.textTheme.bodySmall?.copyWith(color: context.textHint)),
                                  ]),
                                ]),
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
}
