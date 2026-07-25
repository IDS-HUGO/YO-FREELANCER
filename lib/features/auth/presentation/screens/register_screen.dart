// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../domain/entities/user_entity.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  UserType? _selectedType;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _usernameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedType == null) {
      showAppSnackBar(context, 'Selecciona tu tipo de cuenta', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authViewModelProvider.notifier).register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      username: _usernameCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      userType: _selectedType!,
      phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text.trim(),
    );
    if (!ok && mounted) {
      final err = ref.read(authViewModelProvider).error;
      showAppSnackBar(context, err ?? 'Error al registrarse', isError: true);
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
                const SizedBox(height: AppSpacing.xxxl),
                Text('Crear\ncuenta',
                    style: context.textTheme.displaySmall?.copyWith(height: 1.2)),
                const SizedBox(height: AppSpacing.sm),
                Text('Elige cómo quieres usar la plataforma',
                    style: context.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xxl),

                // Tipo de usuario
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<UserType>(
                    segments: const [
                      ButtonSegment(
                        value: UserType.yoer,
                        label: Text('YOER'),
                        icon: Text('🔧'),
                      ),
                      ButtonSegment(
                        value: UserType.client,
                        label: Text('Cliente'),
                        icon: Text('🛒'),
                      ),
                    ],
                    selected: _selectedType == null ? const {} : {_selectedType!},
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => setState(
                      () => _selectedType = selection.isEmpty ? null : selection.first,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _selectedTypeDescription,
                    key: ValueKey(_selectedType),
                    style: context.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                _field(_nameCtrl,     'NOMBRE COMPLETO',  'Juan Pérez',         Icons.person_outline_rounded),
                const SizedBox(height: AppSpacing.lg),
                _field(_usernameCtrl, 'USUARIO',          '@tu_usuario',         Icons.alternate_email_rounded),
                const SizedBox(height: AppSpacing.lg),
                _field(_emailCtrl,    'CORREO',           'correo@email.com',    Icons.mail_outline_rounded,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    }),
                const SizedBox(height: AppSpacing.lg),
                _field(_phoneCtrl,    'TELÉFONO (OPCIONAL)', '+52 55 1234 5678', Icons.phone_outlined,
                    type: TextInputType.phone, required: false),
                const SizedBox(height: AppSpacing.lg),
                _passwordField(),
                const SizedBox(height: AppSpacing.lg),
                _confirmField(),
                const SizedBox(height: AppSpacing.xxxl),

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
                              child: CircularProgressIndicator(strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Crear Cuenta', key: ValueKey('label')),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('¿Ya tienes cuenta? ', style: context.textTheme.bodyMedium),
                  InkWell(
                    borderRadius: AppRadius.smR,
                    onTap: () => context.go(AppRoutes.login),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs / 2),
                      child: Text('Inicia sesión',
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

  String get _selectedTypeDescription {
    switch (_selectedType) {
      case UserType.yoer:
        return 'Ofrecerás tus servicios a clientes en la plataforma';
      case UserType.client:
        return 'Contratarás los servicios de los YOERs';
      case null:
        return 'Elige el tipo de cuenta que quieres crear';
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: context.textTheme.labelLarge?.copyWith(letterSpacing: 1.2)),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        style: context.textTheme.bodyLarge,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 18)),
        validator: validator ?? (v) {
          if (required && (v == null || v.isEmpty)) return 'Campo requerido';
          return null;
        },
      ),
    ]);
  }

  Widget _passwordField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('CONTRASEÑA', style: context.textTheme.labelLarge?.copyWith(letterSpacing: 1.2)),
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
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo requerido';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    ),
  ]);

  Widget _confirmField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('CONFIRMAR CONTRASEÑA', style: context.textTheme.labelLarge?.copyWith(letterSpacing: 1.2)),
    const SizedBox(height: AppSpacing.sm),
    TextFormField(
      controller: _confirmCtrl,
      obscureText: _obscureConfirm,
      style: context.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: '••••••••',
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo requerido';
        if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
        return null;
      },
    ),
  ]);
}
