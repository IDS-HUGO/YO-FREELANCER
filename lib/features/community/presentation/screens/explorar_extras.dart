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
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Divider(color: context.border),
        const SizedBox(height: 24),

        // ── Radar teaser ─────────────────────────────────────────────────
        GestureDetector(
          onTap: () => _showBecomeYoerSheet(context, '¿Puedes resolver tareas cerca de ti?',
              'El Radar muestra tareas urgentes y trabajos disponibles para YOERs. Crea tu cuenta YOER para verlas y postularte.'),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.warningOrange.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: context.cardInner, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.radar_rounded, color: AppTheme.warningOrange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Tareas urgentes cerca de ti',
                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('Conviértete en YOER y ayuda a resolverlas',
                      style: TextStyle(color: context.textSecondary, fontSize: 11)),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textHint),
            ]),
          ),
        ),
        const SizedBox(height: 28),

        // ── En busca de tu talento ───────────────────────────────────────
        Text('EN BUSCA DE TU TALENTO',
            style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showTalentDialog(context),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient(context.isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.border, width: 0.5),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.brandGreen, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('¿No sabes qué se te da bien o quieres desarrollarlo?',
                      style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Cuéntanos y te sugerimos cursos, voluntariados y actividades',
                      style: TextStyle(color: context.textSecondary, fontSize: 11)),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 28),

        // ── Eventos cercanos ─────────────────────────────────────────────
        Text('EVENTOS CERCA DE TI',
            style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        events.when(
          data: (list) => list.isEmpty
              ? Text('Sin eventos próximos por ahora', style: TextStyle(color: context.textSecondary, fontSize: 12))
              : SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final e = list[i];
                      return Container(
                        width: 220,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.border, width: 0.5),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(DateFormat('d MMM', 'es').format(e.startsAt),
                              style: const TextStyle(color: AppTheme.brandGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          if (e.address != null)
                            Row(children: [
                              Icon(Icons.location_on_outlined, size: 12, color: context.textHint),
                              const SizedBox(width: 4),
                              Expanded(child: Text(e.address!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: context.textHint, fontSize: 10))),
                            ]),
                        ]),
                      );
                    },
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
          error: (_, __) => Text('No se pudieron cargar los eventos', style: TextStyle(color: context.textHint, fontSize: 12)),
        ),
        const SizedBox(height: 28),

        // ── Insignias recientes ──────────────────────────────────────────
        Text('LOGROS RECIENTES DE YOERS',
            style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        badgeFeed.when(
          data: (list) => list.isEmpty
              ? Text('Aún no hay logros para mostrar', style: TextStyle(color: context.textSecondary, fontSize: 12))
              : Column(children: list.take(5).map((b) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.border, width: 0.5),
                    ),
                    child: Row(children: [
                      UserAvatar(imageUrl: b.yoerImageUrl, initials: b.yoerName.isNotEmpty ? b.yoerName[0].toUpperCase() : '?', size: 34),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(style: TextStyle(fontSize: 12, color: context.textSecondary), children: [
                            TextSpan(text: b.yoerName, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w700)),
                            const TextSpan(text: ' obtuvo la insignia '),
                            TextSpan(text: b.badgeName, style: const TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(b.badgeIcon ?? '🏅', style: const TextStyle(fontSize: 18)),
                    ]),
                  )).toList()),
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen)),
          error: (_, __) => Text('No se pudieron cargar los logros', style: TextStyle(color: context.textHint, fontSize: 12)),
        ),
        const SizedBox(height: 28),

        // ── Ranking teaser ───────────────────────────────────────────────
        Row(children: [
          Text('TOP YOERS', style: TextStyle(color: context.textHint, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(AppRoutes.ranking),
            child: const Text('Ver todo', style: TextStyle(color: AppTheme.brandGreen, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 12),
        if (ranking.isLoading)
          const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
        else if (ranking.entries.isEmpty)
          Text('Sin datos suficientes todavía', style: TextStyle(color: context.textSecondary, fontSize: 12))
        else
          ...ranking.entries.take(3).map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.border, width: 0.5),
                ),
                child: Row(children: [
                  UserAvatar(imageUrl: e.profileImageUrl, initials: e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : '?', size: 32),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.fullName, style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.w700))),
                  RatingStars(rating: e.rating, size: 13),
                ]),
              )),
      ]),
    );
  }

  void _showBecomeYoerSheet(BuildContext context, String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(body, style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
          backgroundColor: context.card,
          title: Text('Cuéntanos de ti', style: TextStyle(color: context.textPrimary)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: likeCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: '¿Qué te gusta hacer?'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: level,
              dropdownColor: context.card,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Nivel'),
              items: const ['No sé nada', 'Básico', 'Medio', 'Avanzado']
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => level = v ?? level),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
            ElevatedButton(
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
