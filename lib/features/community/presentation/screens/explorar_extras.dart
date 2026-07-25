// lib/features/community/presentation/screens/explorar_extras.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../ranking/data/datasources/ranking_remote_datasource.dart' show rankingViewModelProvider;
import '../../data/datasources/community_remote_datasource.dart';

/// Secciones de descubrimiento debajo del catálogo de servicios en Explorar:
/// Radar (teaser), "en busca de tu talento", eventos cercanos, insignias
/// recientes y ranking. Ver docs/EXPLORAR.docx para la referencia original.
class ExplorarExtras extends ConsumerStatefulWidget {
  const ExplorarExtras({super.key});
  @override
  ConsumerState<ExplorarExtras> createState() => _ExplorarExtrasState();
}

class _ExplorarExtrasState extends ConsumerState<ExplorarExtras> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(rankingViewModelProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(upcomingEventsProvider);
    final badgeFeed = ref.watch(badgeFeedProvider);
    final ranking = ref.watch(rankingViewModelProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl, AppSpacing.sm, AppSpacing.xxl, AppSpacing.xxxl + AppSpacing.sm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Divider(),
        const SizedBox(height: AppSpacing.xxl),

        // ── Radar teaser ─────────────────────────────────────────────────
        Card(
          color: context.colors.tertiaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.xlR,
            side: BorderSide(color: context.colors.tertiary.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            borderRadius: AppRadius.xlR,
            onTap: () => _showBecomeYoerSheet(context, '¿Puedes resolver tareas cerca de ti?',
                'El Radar muestra tareas urgentes y trabajos disponibles para YOERs. Crea tu cuenta YOER para verlas y postularte.'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: context.cardInner, borderRadius: AppRadius.mdR),
                  child: Icon(Icons.radar_rounded, color: context.colors.tertiary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tareas urgentes cerca de ti', style: context.textTheme.titleSmall),
                    Text('Conviértete en YOER y ayuda a resolverlas', style: context.textTheme.bodySmall),
                  ]),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textHint),
              ]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

        // ── En busca de tu talento ───────────────────────────────────────
        Text('EN BUSCA DE TU TALENTO',
            style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: InkWell(
            borderRadius: AppRadius.xlR,
            onTap: () => _showTalentDialog(context),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(children: [
                Icon(Icons.auto_awesome_rounded, color: context.colors.primary, size: 26),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('¿No sabes qué se te da bien o quieres desarrollarlo?',
                        style: context.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Cuéntanos y te sugerimos cursos, voluntariados y actividades',
                        style: context.textTheme.bodySmall),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

        // ── Eventos cercanos ─────────────────────────────────────────────
        Text('EVENTOS CERCA DE TI',
            style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: events.when(
            data: (list) => list.isEmpty
                ? Text('Sin eventos próximos por ahora',
                    key: const ValueKey('events-empty'), style: context.textTheme.bodySmall)
                : SizedBox(
                    key: const ValueKey('events-data'),
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                      itemBuilder: (_, i) {
                        final e = list[i];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: SizedBox(
                              width: 220,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  DateFormat('d MMM', 'es').format(e.startsAt),
                                  style: TextStyle(
                                    color: context.colors.primary, fontSize: 11, fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(e.title,
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                    style: context.textTheme.titleSmall),
                                const Spacer(),
                                if (e.address != null)
                                  Row(children: [
                                    Icon(Icons.location_on_outlined, size: 12, color: context.textHint),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(e.address!,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: context.textHint, fontSize: 10)),
                                    ),
                                  ]),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            loading: () => const Center(key: ValueKey('events-loading'), child: CircularProgressIndicator()),
            error: (_, __) => Text('No se pudieron cargar los eventos',
                key: const ValueKey('events-error'), style: context.textTheme.bodySmall),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

        // ── Insignias recientes ──────────────────────────────────────────
        Text('LOGROS RECIENTES DE YOERS',
            style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: badgeFeed.when(
            data: (list) => list.isEmpty
                ? Text('Aún no hay logros para mostrar',
                    key: const ValueKey('badges-empty'), style: context.textTheme.bodySmall)
                : Column(
                    key: const ValueKey('badges-data'),
                    children: list.take(5).map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(children: [
                                UserAvatar(
                                  imageUrl: b.yoerImageUrl,
                                  initials: b.yoerName.isNotEmpty ? b.yoerName[0].toUpperCase() : '?',
                                  size: 34,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(style: context.textTheme.bodySmall, children: [
                                      TextSpan(
                                        text: b.yoerName,
                                        style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700),
                                      ),
                                      const TextSpan(text: ' obtuvo la insignia '),
                                      TextSpan(
                                        text: b.badgeName,
                                        style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.w700),
                                      ),
                                    ]),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(b.badgeIcon ?? '🏅', style: const TextStyle(fontSize: 18)),
                              ]),
                            ),
                          ),
                        )).toList(),
                  ),
            loading: () => const Center(key: ValueKey('badges-loading'), child: CircularProgressIndicator()),
            error: (_, __) => Text('No se pudieron cargar los logros',
                key: const ValueKey('badges-error'), style: context.textTheme.bodySmall),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),

        // ── Ranking teaser ───────────────────────────────────────────────
        Row(children: [
          Text('TOP YOERS',
              style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const Spacer(),
          TextButton(
            onPressed: () => context.push(AppRoutes.ranking),
            child: const Text('Ver todo'),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ranking.isLoading
              ? const Center(key: ValueKey('ranking-loading'), child: CircularProgressIndicator())
              : ranking.entries.isEmpty
                  ? Text('Sin datos suficientes todavía',
                      key: const ValueKey('ranking-empty'), style: context.textTheme.bodySmall)
                  : Column(
                      key: const ValueKey('ranking-data'),
                      children: ranking.entries.take(3).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Row(children: [
                                  UserAvatar(
                                    imageUrl: e.profileImageUrl,
                                    initials: e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : '?',
                                    size: 32,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(child: Text(e.fullName, style: context.textTheme.titleSmall)),
                                  RatingStars(rating: e.rating, size: 13),
                                ]),
                              ),
                            ),
                          )).toList(),
                    ),
        ),
      ]),
    );
  }

  void _showBecomeYoerSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: context.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: context.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRoutes.register);
              },
              child: const Text('Crear cuenta YOER'),
            ),
          ),
        ]),
      ),
    );
  }

  void _showTalentDialog(BuildContext context) {
    final likeCtrl = TextEditingController();
    String level = 'Básico';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Cuéntanos de ti'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: likeCtrl,
              decoration: const InputDecoration(labelText: '¿Qué te gusta hacer?'),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: level,
              decoration: const InputDecoration(labelText: 'Nivel'),
              items: const ['No sé nada', 'Básico', 'Medio', 'Avanzado']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => level = v ?? level),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showBecomeYoerSheet(context, '¡Vamos a desarrollarlo!',
                    'Con esa habilidad puedes empezar a ofrecer servicios como YOER, tomar cursos o unirte a voluntariados relacionados. Crea tu cuenta para explorar todo lo disponible.');
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
