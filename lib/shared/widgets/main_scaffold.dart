// lib/shared/widgets/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../app/router/app_router.dart';
import '../theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final UserType userType;
  final Widget child;

  const MainScaffold({
    super.key,
    required this.userType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _BottomNavBar(userType: userType),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final UserType userType;

  const _BottomNavBar({required this.userType});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = context.isDark;

    final items = userType == UserType.yoer
        ? _yoerItems
        : _clientItems;

    final currentIndex = _currentIndex(location, items);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgDark : AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.borderDark : const Color(0xFFE0EAE2),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              return Expanded(
                child: _NavItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => context.go(item.route),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  int _currentIndex(String location, List<_NavItemData> items) {
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].route)) return i;
    }
    return 0;
  }

  static const _yoerItems = [
    _NavItemData(icon: Icons.home_rounded,     label: 'Inicio',  route: AppRoutes.yoerHome),
    _NavItemData(icon: Icons.store_rounded,    label: 'Vitrina', route: AppRoutes.yoerVitrina),
    _NavItemData(icon: Icons.person_rounded,   label: 'Perfil',  route: AppRoutes.yoerProfile),
  ];

  static const _clientItems = [
    _NavItemData(icon: Icons.explore_rounded,  label: 'Explorar', route: AppRoutes.clientHome),
    _NavItemData(icon: Icons.book_rounded,     label: 'Reservas', route: AppRoutes.clientBookings),
    _NavItemData(icon: Icons.person_rounded,   label: 'Perfil',   route: AppRoutes.clientProfile),
  ];
}

class _NavItemData {
  final IconData icon;
  final String label;
  final String route;
  const _NavItemData({required this.icon, required this.label, required this.route});
}

class _NavItem extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.brandGreen.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                item.icon,
                color: isSelected ? AppTheme.brandGreen : AppTheme.textHintDark,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppTheme.brandGreen : AppTheme.textHintDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets reutilizables compartidos ─────────────────────────────────────────

/// Chip de estado de reserva
class BookingStatusChip extends StatelessWidget {
  final String status;

  const BookingStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (Color, Color, String) _resolve(String status) {
    switch (status) {
      case 'PENDIENTE':   return (AppTheme.warningOrange, AppTheme.warningOrange.withValues(alpha: 0.15), 'Pendiente');
      case 'CONFIRMADA':  return (AppTheme.brandGreen, AppTheme.brandGreen.withValues(alpha: 0.15), 'Confirmada');
      case 'EN_PROGRESO': return (AppTheme.infoBlue, AppTheme.infoBlue.withValues(alpha: 0.15), 'En progreso');
      case 'COMPLETADA':  return (AppTheme.brandGreen, AppTheme.brandGreen.withValues(alpha: 0.15), 'Completada');
      case 'CANCELADA':   return (AppTheme.alertRedLight, AppTheme.alertRedLight.withValues(alpha: 0.15), 'Cancelada');
      case 'RECHAZADA':   return (AppTheme.alertRedLight, AppTheme.alertRedLight.withValues(alpha: 0.15), 'Rechazada');
      default:            return (AppTheme.textHintDark, AppTheme.textHintDark.withValues(alpha: 0.15), status);
    }
  }
}

/// Overlay de carga motivacional
class LoadingOverlay extends StatefulWidget {
  final String message;

  const LoadingOverlay({super.key, this.message = 'Cargando...'});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {
  int _phraseIndex = 0;
  static const _phrases = [
    'Tu esfuerzo de hoy es el éxito de mañana.',
    'Cada trabajo bien hecho te acerca a tu mejor versión.',
    'Disciplina y constancia vencen al talento sin acción.',
    'Sigue avanzando: todo gran logro comienza pequeño.',
    'El progreso diario construye resultados extraordinarios.',
  ];

  @override
  void initState() {
    super.initState();
    _cycle();
  }

  void _cycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _phrases.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandGreen),
            ),
            const SizedBox(height: 24),
            Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  _phrases[_phraseIndex],
                  key: ValueKey(_phraseIndex),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.brandGreenAccent.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rating stars widget
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;

  const RatingStars({super.key, required this.rating, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: const Color(0xFFFFC107), size: size),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size - 2,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Avatar circular con fallback de iniciales
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.cardDark,
        border: Border.all(color: AppTheme.borderDark, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials,
            )
          : _initials,
    );
  }

  Widget get _initials => Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.brandGreen,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

/// Tarjeta de sección con header
class SectionCard extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandGreen,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Snackbar helper
void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.alertRed : AppTheme.brandGreenDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
