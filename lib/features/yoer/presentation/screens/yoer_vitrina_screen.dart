// lib/features/yoer/presentation/screens/yoer_vitrina_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../services/presentation/viewmodels/service_viewmodel.dart';
import '../../../services/domain/entities/service_entity.dart';

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
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'toggle') onToggle();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'toggle',
                      child: Text(service.isActive ? 'Desactivar' : 'Activar')),
                  PopupMenuItem(value: 'delete',
                      child: Text('Eliminar', style: TextStyle(color: context.colors.error))),
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
              const Spacer(),
              Text(service.priceLabel,
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
      ),
    );
  }
}
