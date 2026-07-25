// lib/features/auth/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Tu email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final email = ctrl.text.trim();
              Navigator.pop(ctx);
              if (email.isEmpty) return;
              final ok = await ref.read(authViewModelProvider.notifier).resetPasswordForEmail(email);
              if (!mounted) return;
              showAppSnackBar(
                context,
                ok
                    ? 'Te enviamos un correo para restablecer tu contraseña'
                    : 'No se pudo enviar el correo, intenta de nuevo',
                isError: !ok,
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authViewModelProvider.notifier).login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!ok && mounted) {
      final err = ref.read(authViewModelProvider).error;
      showAppSnackBar(context, err ?? 'Error al iniciar sesión', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                IconButton(
                  onPressed: () => context.go(AppRoutes.welcome),
                  style: IconButton.styleFrom(
                    side: BorderSide(color: context.colors.outlineVariant),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                ),
                const SizedBox(height: AppSpacing.huge),
                Text('Bienvenido\nde vuelta',
                    style: context.textTheme.displaySmall?.copyWith(height: 1.2)),
                const SizedBox(height: AppSpacing.sm),
                Text('Introduce tus datos para continuar',
                    style: context.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxxl),

                // Email
                _label('CORREO ELECTRÓNICO'),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: context.textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    hintText: 'tu@email.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Password
                _label('CONTRASEÑA'),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  style: context.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Botón
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: state.isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ))
                          : const Text('Iniciar Sesión', key: ValueKey('label')),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('¿No tienes cuenta? ', style: context.textTheme.bodyMedium),
                  InkWell(
                    borderRadius: AppRadius.smR,
                    onTap: () => context.go(AppRoutes.register),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs / 2),
                      child: Text('Regístrate',
                          style: context.textTheme.labelLarge?.copyWith(color: context.colors.primary)),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: context.textTheme.labelLarge?.copyWith(letterSpacing: 1.2));
}
