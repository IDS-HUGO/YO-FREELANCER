// lib/features/yoer/presentation/screens/yoer_vitrina_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
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

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(children: [
              const Text('Mi Vitrina',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(AppRoutes.createService),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Lista
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                : state.userServices.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                        itemCount: state.userServices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
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
        ]),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.store_outlined, color: AppTheme.textHintDark, size: 64),
      const SizedBox(height: 16),
      const Text('Sin servicios publicados',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Crea tu primer servicio', style: TextStyle(color: AppTheme.textSecondaryDark)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => context.push(AppRoutes.createService),
        child: const Text('Crear Servicio'),
      ),
    ]));
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderDark, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: service.isActive
                    ? AppTheme.brandGreen.withOpacity(0.15)
                    : AppTheme.textHintDark.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(service.category.emoji + ' ' + service.category.displayName,
                  style: TextStyle(
                    color: service.isActive ? AppTheme.brandGreen : AppTheme.textHintDark,
                    fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              color: AppTheme.cardDark,
              onSelected: (v) {
                if (v == 'toggle') onToggle();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'toggle',
                    child: Text(service.isActive ? 'Desactivar' : 'Activar',
                        style: const TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete',
                    child: Text('Eliminar', style: TextStyle(color: AppTheme.alertRedLight))),
              ],
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppTheme.textSecondaryDark, size: 20),
            ),
          ]),
          const SizedBox(height: 10),
          Text(service.title,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(service.description,
              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          Row(children: [
            RatingStars(rating: service.rating),
            const SizedBox(width: 6),
            Text('(${service.totalReviews})',
                style: TextStyle(color: AppTheme.textHintDark, fontSize: 11)),
            const Spacer(),
            Text(service.priceLabel,
                style: const TextStyle(color: AppTheme.brandGreen, fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        ]),
      ),
    );
  }
}
