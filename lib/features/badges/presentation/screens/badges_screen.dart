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

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Insignias')),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${state.earned.length} de ${state.catalog.length} desbloqueadas',
                      style: TextStyle(color: context.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.0,
                      ),
                      itemCount: state.catalog.length,
                      itemBuilder: (_, i) {
                        final badge = state.catalog[i];
                        final earned = state.isEarned(badge.code);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: earned ? context.cardInner : context.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: earned ? AppTheme.brandGreen.withValues(alpha: 0.5) : context.border,
                              width: earned ? 1 : 0.5,
                            ),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Opacity(
                              opacity: earned ? 1 : 0.35,
                              child: Text(badge.icon ?? '🏅', style: const TextStyle(fontSize: 36)),
                            ),
                            const SizedBox(height: 10),
                            Text(badge.name, textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: earned ? context.textPrimary : context.textHint,
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 4),
                            Text(badge.description ?? '', textAlign: TextAlign.center, maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: context.textHint, fontSize: 10)),
                          ]),
                        );
                      },
                    ),
                  ),
                ]),
              ),
      ),
    );
  }
}
