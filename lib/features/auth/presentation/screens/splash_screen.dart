// lib/features/auth/presentation/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _scale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: AppRadius.xxlR,
                      border: Border.all(color: context.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Ý',
                        style: TextStyle(
                          fontSize: 56,
                          color: AppTheme.brandGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'YO FREE-LANCER',
                    style: context.textTheme.headlineSmall?.copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),
                  Text(
                    'Tu trabajo habla por ti',
                    style: context.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.huge + AppSpacing.md),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WELCOME SCREEN
// lib/features/auth/presentation/screens/welcome_screen.dart

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideY;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideY = Tween<double>(begin: 40, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl + AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.greenGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brandGreen.withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Ý',
                    style: TextStyle(
                      fontSize: 64,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl + AppSpacing.xs),
              Text(
                'YO FREE-LANCER',
                style: context.textTheme.headlineMedium?.copyWith(letterSpacing: 2.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Conecta talento con oportunidades en México',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
              const Spacer(),

              // Botones animados
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _slideY.value),
                  child: Opacity(opacity: _fade.value, child: child),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Iniciar Sesión'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md + 2),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: const Text('Crear Cuenta'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    InkWell(
                      borderRadius: AppRadius.smR,
                      onTap: () => context.go(AppRoutes.clientHome),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          'Explorar sin cuenta',
                          style: context.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
