import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../community/presentation/screens/explorar_extras.dart';
import '../../../services/presentation/viewmodels/service_viewmodel.dart';
import '../../../services/domain/entities/service_entity.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});
  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  ServiceCategory? _selectedCat;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(serviceViewModelProvider.notifier).getAllServices();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user  = ref.watch(currentUserProvider);
    final state = ref.watch(serviceViewModelProvider);

    final displayed = _selectedCat != null
        ? state.filteredByCategory
        : _searchCtrl.text.isNotEmpty
            ? state.searchResults
            : state.services;

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          // Encabezado colapsable con saludo, notificaciones y avatar
          SliverAppBar(
            backgroundColor: context.bg,
            pinned: true,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            centerTitle: false,
            titleSpacing: AppSpacing.xxl,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: AppSpacing.xxl, bottom: AppSpacing.md,
              ),
              title: Text('Hola, ${user?.firstName ?? 'Usuario'} 👋',
                  style: context.textTheme.titleMedium),
              background: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.huge, AppSpacing.xxl, 0),
                child: Text('¿Qué servicio necesitas hoy?',
                    style: context.textTheme.bodySmall),
              ),
            ),
            actions: [
              if (user != null) ...[
                NotificationBell(userId: user.id),
                const SizedBox(width: AppSpacing.sm),
              ],
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xxl),
                child: UserAvatar(
                  imageUrl: user?.profileImageUrl,
                  initials: user?.initials ?? '?',
                  size: 40,
                ),
              ),
            ],
          ),

          // Buscador y categorías
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() {});
                  if (v.length > 2) ref.read(serviceViewModelProvider.notifier).searchServices(v);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () => setState(() => _searchCtrl.clear()),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Categorías
              SizedBox(
                height: 38,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _catChip(null, 'Todas'),
                  ...ServiceCategory.values.map((c) => _catChip(c, '${c.emoji} ${c.displayName}')),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Carrusel de Servicios Patrocinados (Yoer Ads)
              _SponsoredServicesCarousel(
                services: state.services.where((s) => s.isPromoted).toList().isNotEmpty
                    ? state.services.where((s) => s.isPromoted).toList()
                    : state.services.take(3).toList(),
                onTap: (s) => context.push('/service/${s.id}'),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                _selectedCat != null
                    ? 'SERVICIOS EN ${_selectedCat!.displayName.toUpperCase()}'
                    : _searchCtrl.text.isNotEmpty
                        ? 'RESULTADOS DE BÚSQUEDA'
                        : 'TODOS LOS SERVICIOS',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.textHint,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ]),
          )),

          // Grid de servicios
          state.isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : displayed.isEmpty
                  ? SliverFillRemaining(child: Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off_rounded, color: context.colors.outline, size: 56),
                        const SizedBox(height: AppSpacing.md),
                        Text('Sin resultados', style: context.textTheme.bodyMedium),
                      ])))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.sm),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _ClientServiceCard(
                              service: displayed[i],
                              onTap: () => context.push('/service/${displayed[i].id}'),
                            ),
                          ),
                          childCount: displayed.length,
                        ),
                      ),
                    ),

          // Explorar: radar, talento, eventos, insignias y ranking
          const SliverToBoxAdapter(child: ExplorarExtras()),
        ]),
      ),
    );
  }

  Widget _catChip(ServiceCategory? cat, String label) {
    final selected = _selectedCat == cat;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) {
          setState(() => _selectedCat = cat);
          if (cat != null) {
            ref.read(serviceViewModelProvider.notifier).filterByCategory(cat);
          } else {
            ref.read(serviceViewModelProvider.notifier).getAllServices();
          }
        },
      ),
    );
  }
}

class _ClientServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final VoidCallback onTap;
  const _ClientServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgR,
        side: service.isPromoted
            ? const BorderSide(color: Color(0xFFFF6B3D), width: 1.2)
            : BorderSide(color: context.border, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(
            children: [
              if (service.images.isNotEmpty)
                Image.network(
                  service.images.first,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: context.colors.surfaceContainerHighest,
                    child: Icon(Icons.image_not_supported_outlined, color: context.colors.outline),
                  ),
                )
              else
                Container(
                  height: 80,
                  width: double.infinity,
                  color: AppTheme.brandGreen.withValues(alpha: 0.08),
                  child: Center(
                    child: Text(
                      service.category.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
              if (service.isPromoted)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B3D),
                      borderRadius: AppRadius.pillR,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Patrocinado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Text('${service.category.emoji} ${service.category.displayName}',
                      style: context.textTheme.labelMedium?.copyWith(color: context.colors.primary)),
                  const Spacer(),
                  if (service.isPromoted)
                    const Text(
                      '⭐ Recomendado',
                      style: TextStyle(
                        color: Color(0xFFFF6B3D),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(service.title,
                  style: context.textTheme.titleSmall,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                UserAvatar(
                  imageUrl: service.yoerImageUrl,
                  initials: service.yoerName.isNotEmpty ? service.yoerName[0].toUpperCase() : '?',
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(service.yoerName,
                    style: context.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis)),
                RatingStars(rating: service.rating),
                const SizedBox(width: AppSpacing.sm),
                Text(service.priceLabel,
                    style: context.textTheme.titleSmall?.copyWith(color: context.colors.primary)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Carrusel VIP para destacar Yoers y Servicios patrocinados
class _SponsoredServicesCarousel extends StatelessWidget {
  final List<ServiceEntity> services;
  final ValueChanged<ServiceEntity> onTap;

  const _SponsoredServicesCarousel({
    required this.services,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: AppTheme.brandGreen, size: 18),
            const SizedBox(width: 4),
            Text(
              'SERVICIOS RECOMENDADOS',
              style: context.textTheme.labelSmall?.copyWith(
                color: context.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.textHint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Patrocinado',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (ctx, i) {
              final s = services[i];
              return Container(
                width: 280,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.card,
                      AppTheme.brandGreen.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.lgR,
                  border: Border.all(
                    color: s.isPromoted ? const Color(0xFFFF6B3D).withValues(alpha: 0.8) : AppTheme.brandGreen.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(s),
                    borderRadius: AppRadius.lgR,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              UserAvatar(
                                imageUrl: s.yoerImageUrl,
                                initials: s.yoerName.isNotEmpty ? s.yoerName[0].toUpperCase() : '?',
                                size: 32,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.yoerName,
                                      style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${s.category.emoji} ${s.category.displayName}',
                                      style: TextStyle(
                                        color: context.textHint,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandGreen.withValues(alpha: 0.2),
                                  borderRadius: AppRadius.pillR,
                                ),
                                child: Text(
                                  s.priceLabel,
                                  style: const TextStyle(
                                    color: AppTheme.brandGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            s.title,
                            style: context.textTheme.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              RatingStars(rating: s.rating > 0 ? s.rating : 5.0),
                              const SizedBox(width: 4),
                              Text(
                                s.rating > 0 ? '(${s.totalReviews})' : '5.0 (Top)',
                                style: context.textTheme.labelSmall?.copyWith(fontSize: 11),
                              ),
                              const Spacer(),
                              const Text(
                                'Ver detalle →',
                                style: TextStyle(
                                  color: AppTheme.brandGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
