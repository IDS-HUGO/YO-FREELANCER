// lib/features/ranking/presentation/screens/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
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

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Ranking de YOERs')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: RankingMetric.values.map((m) {
                final selected = state.metric == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(rankingViewModelProvider.notifier).load(metric: m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.brandGreen : context.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? AppTheme.brandGreen : context.border),
                      ),
                      child: Text(m.displayName, textAlign: TextAlign.center,
                          style: TextStyle(color: selected ? Colors.white : context.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                : state.entries.isEmpty
                    ? Center(child: Text('Sin datos suficientes todavía', style: TextStyle(color: context.textSecondary)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final e = state.entries[i];
                          final isTop3 = i < 3;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isTop3 ? AppTheme.brandGreen.withValues(alpha: 0.4) : context.border,
                                width: isTop3 ? 1 : 0.5,
                              ),
                            ),
                            child: Row(children: [
                              SizedBox(
                                width: 28,
                                child: Text('${i + 1}',
                                    style: TextStyle(
                                      color: isTop3 ? AppTheme.brandGreen : context.textHint,
                                      fontSize: 16, fontWeight: FontWeight.w800,
                                    )),
                              ),
                              UserAvatar(imageUrl: e.profileImageUrl, initials: e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : '?', size: 42),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(e.fullName, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                  if (e.city != null)
                                    Text(e.city!, style: TextStyle(color: context.textHint, fontSize: 11)),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                RatingStars(rating: e.rating, size: 13),
                                const SizedBox(height: 2),
                                Text('${e.completedJobs} tareas', style: TextStyle(color: context.textHint, fontSize: 10)),
                              ]),
                            ]),
                          );
                        },
                      ),
          ),
        ]),
      ),
    );
  }
}
