import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../services/presentation/viewmodels/service_viewmodel.dart';
import '../../../services/domain/entities/service_entity.dart';
import '../../../services/presentation/widgets/promote_service_sheet.dart';

class YoerVitrinaScreen extends ConsumerStatefulWidget {
  const YoerVitrinaScreen({super.key});
  @override
  ConsumerState<YoerVitrinaScreen> createState() => _YoerVitrinaScreenState();
}

class _YoerVitrinaScreenState extends ConsumerState<YoerVitrinaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(serviceViewModelProvider.notifier).getUserServices(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceViewModelProvider);

    ref.listen(serviceViewModelProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showAppErrorDialog(context, message: next.error!);
        ref.read(serviceViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Mi Vitrina'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: FilledButton.icon(
              onPressed: () => context.push(AppRoutes.createService),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuevo'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: state.isLoading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(color: AppTheme.brandGreen),
              )
            : state.userServices.isEmpty
                ? _empty(context, key: const ValueKey('empty'))
                : ListView.separated(
                    key: const ValueKey('list'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxxl,
                    ),
                    itemCount: state.userServices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md + 2),
                    itemBuilder: (_, i) => _ServiceCard(
                      service: state.userServices[i],
                      onTap: () => context.push('/service/${state.userServices[i].id}'),
                      onToggle: () => ref.read(serviceViewModelProvider.notifier)
                          .toggleServiceStatus(state.userServices[i].id),
                      onDelete: () => ref.read(serviceViewModelProvider.notifier)
                          .deleteService(state.userServices[i].id),
                    ),
                  ),
      ),
    );
  }

  Widget _empty(BuildContext context, {Key? key}) {
    return Center(
      key: key,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.store_outlined, color: context.textHint, size: 64),
        const SizedBox(height: AppSpacing.lg),
        Text('Sin servicios publicados', style: context.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Crea tu primer servicio', style: context.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xxl),
        FilledButton(
          onPressed: () => context.push(AppRoutes.createService),
          child: const Text('Crear Servicio'),
        ),
      ]),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.xlR,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: service.isActive
                      ? AppTheme.brandGreen.withValues(alpha: 0.15)
                      : context.textHint.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillR,
                ),
                child: Text('${service.category.emoji} ${service.category.displayName}',
                    style: TextStyle(
                      color: service.isActive ? AppTheme.brandGreen : context.textHint,
                      fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              if (service.isPromoted) ...[
                const SizedBox(width: AppSpacing.xs + 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B3D).withValues(alpha: 0.18),
                    borderRadius: AppRadius.pillR,
                    border: Border.all(color: const Color(0xFFFF6B3D), width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFFFF6B3D), size: 12),
                      SizedBox(width: 2),
                      Text(
                        'Patrocinado',
                        style: TextStyle(
                          color: Color(0xFFFF6B3D),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'toggle') onToggle();
                  if (v == 'delete') onDelete();
                  if (v == 'promote') PromoteServiceSheet.show(context, service);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'promote',
                      child: Row(children: [
                        Icon(Icons.campaign_rounded, color: AppTheme.brandGreen, size: 18),
                        SizedBox(width: 8),
                        Text('Impulsar con Ads'),
                      ])),
                  PopupMenuItem(value: 'toggle',
                      child: Text('Activar / Desactivar')),
                  PopupMenuItem(value: 'delete',
                      child: Text('Eliminar', style: TextStyle(color: AppTheme.alertRed))),
                ],
                icon: Icon(Icons.more_vert_rounded, color: context.textSecondary, size: 20),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(service.title, style: context.textTheme.titleSmall,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(service.description, style: context.textTheme.bodySmall,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.md + 2),
            Row(children: [
              RatingStars(rating: service.rating),
              const SizedBox(width: AppSpacing.xs + 2),
              Text('(${service.totalReviews})', style: context.textTheme.labelSmall),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.visibility_outlined, size: 14, color: context.textHint),
              const SizedBox(width: 3),
              Text('${service.viewsCount} vistas', style: context.textTheme.labelSmall),
              const Spacer(),
              Text(service.priceLabel,
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => PromoteServiceSheet.show(context, service),
                icon: Icon(
                  service.isPromoted ? Icons.insights_rounded : Icons.campaign_rounded,
                  size: 16,
                  color: service.isPromoted ? const Color(0xFFFF6B3D) : AppTheme.brandGreen,
                ),
                label: Text(
                  service.isPromoted ? 'Ver Rendimiento de Campaña' : 'Impulsar con Alcance (Ads)',
                  style: TextStyle(
                    color: service.isPromoted ? const Color(0xFFFF6B3D) : AppTheme.brandGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: service.isPromoted
                        ? const Color(0xFFFF6B3D).withValues(alpha: 0.6)
                        : AppTheme.brandGreen.withValues(alpha: 0.6),
                  ),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
