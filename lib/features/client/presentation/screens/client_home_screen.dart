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
      child: InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${service.category.emoji} ${service.category.displayName}',
                  style: context.textTheme.labelMedium?.copyWith(color: context.colors.primary)),
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
