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
          // Header
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hola, ${user?.firstName ?? 'Usuario'} 👋',
                      style: TextStyle(color: context.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('¿Qué servicio necesitas hoy?',
                      style: TextStyle(color: context.textSecondary, fontSize: 13)),
                ])),
                if (user != null) ...[
                  NotificationBell(userId: user.id),
                  const SizedBox(width: 10),
                ],
                UserAvatar(imageUrl: user?.profileImageUrl, initials: user?.initials ?? '?', size: 44),
              ]),
              const SizedBox(height: 20),

              // Buscador
              TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() {});
                  if (v.length > 2) ref.read(serviceViewModelProvider.notifier).searchServices(v);
                },
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
                  hintStyle: TextStyle(color: context.textHint),
                  prefixIcon: Icon(Icons.search_rounded, color: context.textHint),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () { setState(() => _searchCtrl.clear()); },
                          icon: Icon(Icons.close_rounded, color: context.textHint, size: 18))
                      : null,
                  filled: true,
                  fillColor: context.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.border, width: 0.5)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 18),

              // Categorías
              SizedBox(
                height: 36,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  _catChip(null, 'Todas'),
                  ...ServiceCategory.values.map((c) => _catChip(c, '${c.emoji} ${c.displayName}')),
                ]),
              ),
              const SizedBox(height: 20),
            ]),
          )),

          // Grid de servicios
          state.isLoading
              ? const SliverFillRemaining(child: Center(
                  child: CircularProgressIndicator(color: AppTheme.brandGreen)))
              : displayed.isEmpty
                  ? SliverFillRemaining(child: Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off_rounded, color: context.textHint, size: 56),
                        const SizedBox(height: 12),
                        Text('Sin resultados', style: TextStyle(color: context.textSecondary)),
                      ])))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _ClientServiceCard(
                            service: displayed[i],
                            onTap: () => context.push('/service/${displayed[i].id}'),
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
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCat = cat);
        if (cat != null) {
          ref.read(serviceViewModelProvider.notifier).filterByCategory(cat);
        } else {
          ref.read(serviceViewModelProvider.notifier).getAllServices();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandGreen : context.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.brandGreen : context.border,
            width: 0.5,
          ),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : context.textSecondary,
          fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        )),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.border, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (service.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(service.images.first, height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 100, color: context.cardInner,
                      child: Icon(Icons.image_not_supported_outlined, color: context.textHint))),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${service.category.emoji} ${service.category.displayName}',
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(service.title,
                  style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                UserAvatar(imageUrl: service.yoerImageUrl, initials: service.yoerName.isNotEmpty ? service.yoerName[0].toUpperCase() : '?', size: 28),
                const SizedBox(width: 8),
                Expanded(child: Text(service.yoerName,
                    style: TextStyle(color: context.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis)),
                RatingStars(rating: service.rating),
                const SizedBox(width: 8),
                Text(service.priceLabel,
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
