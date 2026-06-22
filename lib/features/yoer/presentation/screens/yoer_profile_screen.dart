// lib/features/yoer/presentation/screens/yoer_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class YoerProfileScreen extends ConsumerWidget {
  const YoerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            // Cover
            Stack(children: [
              Container(
                height: 160,
                decoration: BoxDecoration(gradient: AppTheme.greenGradient),
              ),
              Positioned(
                bottom: -40, left: 24,
                child: UserAvatar(
                  imageUrl: user?.profileImageUrl,
                  initials: user?.initials ?? '?',
                  size: 80,
                ),
              ),
              Positioned(
                top: 12, right: 12,
                child: IconButton(
                  onPressed: () {},
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 52),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user?.fullName ?? 'YOER',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text('@${user?.username ?? 'usuario'}',
                        style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.brandGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.brandGreen.withOpacity(0.4)),
                    ),
                    child: Text(user?.status.displayName ?? 'Disponible',
                        style: const TextStyle(color: AppTheme.brandGreen,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 16),

                if (user?.bio != null) ...[
                  Text(user!.bio!,
                      style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 16),
                ],

                // Métricas
                Row(children: [
                  _stat('${user?.rating.toStringAsFixed(1) ?? '0.0'}', 'Rating', Icons.star_rounded),
                  _stat('${user?.totalReviews ?? 0}', 'Reseñas', Icons.reviews_outlined),
                  _stat('${user?.completedJobs ?? 0}', 'Trabajos', Icons.check_circle_outline_rounded),
                ]),
                const SizedBox(height: 24),

                // Localización
                if (user?.city != null)
                  _infoRow(Icons.location_on_outlined, '${user?.city}, ${user?.country}'),
                if (user?.phoneNumber != null)
                  _infoRow(Icons.phone_outlined, user!.phoneNumber!),
                _infoRow(Icons.mail_outline_rounded, user?.email ?? ''),

                const SizedBox(height: 28),
                const Divider(color: AppTheme.borderDark),
                const SizedBox(height: 20),

                // Acciones
                _actionTile(Icons.person_outline_rounded, 'Editar perfil', () {}),
                _actionTile(Icons.notifications_outlined, 'Notificaciones', () {}),
                _actionTile(Icons.security_outlined, 'Seguridad y privacidad', () {}),
                _actionTile(Icons.help_outline_rounded, 'Ayuda y soporte', () {}),
                const SizedBox(height: 8),
                _actionTile(Icons.logout_rounded, 'Cerrar sesión', () async {
                  await ref.read(authViewModelProvider.notifier).logout();
                }, color: AppTheme.alertRedLight),
                const SizedBox(height: 40),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderDark, width: 0.5),
        ),
        child: Column(children: [
          Icon(icon, color: AppTheme.brandGreen, size: 18),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: AppTheme.textHintDark, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, color: AppTheme.textSecondaryDark, size: 18),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13)),
      ]),
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: color ?? AppTheme.textSecondaryDark, size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14)),
          const Spacer(),
          if (color == null) const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: AppTheme.textHintDark),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLIENT HOME
// lib/features/client/presentation/screens/client_home_screen.dart

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
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          // Header
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hola, ${user?.firstName ?? 'Usuario'} 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  Text('¿Qué servicio necesitas hoy?',
                      style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13)),
                ])),
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
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
                  hintStyle: TextStyle(color: AppTheme.textHintDark),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textHintDark),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () { setState(() => _searchCtrl.clear()); },
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textHintDark, size: 18))
                      : null,
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.borderDark, width: 0.5)),
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
                  ...ServiceCategory.values.map((c) => _catChip(c, c.emoji + ' ' + c.displayName)),
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
                        const Icon(Icons.search_off_rounded, color: AppTheme.textHintDark, size: 56),
                        const SizedBox(height: 12),
                        Text('Sin resultados', style: TextStyle(color: AppTheme.textSecondaryDark)),
                      ])))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
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
        ]),
      ),
    );
  }

  Widget _catChip(ServiceCategory? cat, String label) {
    final selected = _selectedCat == cat;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCat = cat);
        if (cat != null) ref.read(serviceViewModelProvider.notifier).filterByCategory(cat);
        else ref.read(serviceViewModelProvider.notifier).getAllServices();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.brandGreen : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.brandGreen : AppTheme.borderDark,
            width: 0.5,
          ),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecondaryDark,
          fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        )),
      ),
    );
  }
}

class _ClientServiceCard extends StatelessWidget {
  final service;
  final VoidCallback onTap;
  const _ClientServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderDark, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (service.images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(service.images.first, height: 150, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(height: 100, color: AppTheme.cardInnerDark,
                      child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.textHintDark))),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${service.category.emoji} ${service.category.displayName}',
                  style: const TextStyle(color: AppTheme.brandGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(service.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 10),
              Row(children: [
                UserAvatar(imageUrl: service.yoerImageUrl, initials: service.yoerName.isNotEmpty ? service.yoerName[0].toUpperCase() : '?', size: 28),
                const SizedBox(width: 8),
                Expanded(child: Text(service.yoerName,
                    style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
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

// ── CLIENT BOOKINGS ────────────────────────────────────────────────────────────
class ClientBookingsScreen extends ConsumerStatefulWidget {
  const ClientBookingsScreen({super.key});
  @override
  ConsumerState<ClientBookingsScreen> createState() => _ClientBookingsScreenState();
}

class _ClientBookingsScreenState extends ConsumerState<ClientBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) ref.read(bookingViewModelProvider.notifier).loadBookingsForClient(user.id);
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingViewModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Text('Mis Reservas',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tab,
            indicatorColor: AppTheme.brandGreen,
            labelColor: AppTheme.brandGreen,
            unselectedLabelColor: AppTheme.textHintDark,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [Tab(text: 'Próximas'), Tab(text: 'Completadas'), Tab(text: 'Canceladas')],
          ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
                : TabBarView(controller: _tab, children: [
                    _BookingList(bookings: state.upcomingBookings),
                    _BookingList(bookings: state.completedBookings),
                    _BookingList(bookings: state.cancelledBookings),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List bookings;
  const _BookingList({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.calendar_today_outlined, color: AppTheme.textHintDark, size: 48),
        const SizedBox(height: 12),
        Text('Sin reservas', style: TextStyle(color: AppTheme.textSecondaryDark)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final b = bookings[i];
        return GestureDetector(
          onTap: () => context.push('/booking/${b.id}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderDark, width: 0.5),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(b.serviceName,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                BookingStatusChip(status: b.status.name),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textHintDark),
                const SizedBox(width: 4),
                Text(b.yoerName, style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12)),
                const Spacer(),
                Text('\$${b.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: AppTheme.brandGreen, fontSize: 14, fontWeight: FontWeight.w800)),
              ]),
            ]),
          ),
        );
      },
    );
  }
}

// ── CLIENT PROFILE ─────────────────────────────────────────────────────────────
class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            UserAvatar(imageUrl: user?.profileImageUrl, initials: user?.initials ?? '?', size: 80),
            const SizedBox(height: 14),
            Text(user?.fullName ?? 'Cliente',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            Text('@${user?.username ?? ''}',
                style: TextStyle(color: AppTheme.textSecondaryDark)),
            const SizedBox(height: 32),
            _tile(Icons.person_outline_rounded, 'Editar perfil', () {}),
            _tile(Icons.credit_card_outlined, 'Métodos de pago', () {}),
            _tile(Icons.notifications_outlined, 'Notificaciones', () {}),
            _tile(Icons.help_outline_rounded, 'Ayuda', () {}),
            _tile(Icons.logout_rounded, 'Cerrar sesión', () async {
              await ref.read(authViewModelProvider.notifier).logout();
            }, color: AppTheme.alertRedLight),
          ]),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderDark, width: 0.5)),
        ),
        child: Row(children: [
          Icon(icon, color: color ?? AppTheme.textSecondaryDark, size: 20),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14)),
          const Spacer(),
          if (color == null) const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textHintDark),
        ]),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/presentation/viewmodels/service_viewmodel.dart';
import '../../../services/domain/entities/service_entity.dart';
import '../../../bookings/data/datasources/booking_remote_datasource.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
