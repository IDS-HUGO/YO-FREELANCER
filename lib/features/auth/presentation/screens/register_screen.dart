// lib/features/auth/presentation/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selecciona tu tipo de cuenta'),
        backgroundColor: AppTheme.warningOrange,
      ));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err ?? 'Error al registrarse'),
        backgroundColor: AppTheme.alertRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                IconButton(
                  onPressed: () => context.go(AppRoutes.welcome),
                  icon: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderDark),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Crear\ncuenta',
                    style: TextStyle(
                      color: Colors.white, fontSize: 34,
                      fontWeight: FontWeight.w800, height: 1.2,
                    )),
                const SizedBox(height: 10),
                Text('Elige cómo quieres usar la plataforma',
                    style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 14)),
                const SizedBox(height: 28),

                // Tipo de usuario
                Row(children: [
                  _typeCard(UserType.yoer, '🔧', 'YOER', 'Ofrezco servicios'),
                  const SizedBox(width: 12),
                  _typeCard(UserType.client, '🛒', 'CLIENTE', 'Contrato servicios'),
                ]),
                const SizedBox(height: 24),

                _field(_nameCtrl,     'NOMBRE COMPLETO',  'Juan Pérez',         Icons.person_outline_rounded),
                const SizedBox(height: 14),
                _field(_usernameCtrl, 'USUARIO',          '@tu_usuario',         Icons.alternate_email_rounded),
                const SizedBox(height: 14),
                _field(_emailCtrl,    'CORREO',           'correo@email.com',    Icons.mail_outline_rounded,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Campo requerido';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    }),
                const SizedBox(height: 14),
                _field(_phoneCtrl,    'TELÉFONO (OPCIONAL)', '+52 55 1234 5678', Icons.phone_outlined,
                    type: TextInputType.phone, required: false),
                const SizedBox(height: 14),
                _passwordField(),
                const SizedBox(height: 14),
                _confirmField(),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: state.isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Text('Crear Cuenta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('¿Ya tienes cuenta? ',
                      style: TextStyle(color: AppTheme.textSecondaryDark)),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: const Text('Inicia sesión',
                        style: TextStyle(color: AppTheme.brandGreen, fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeCard(UserType type, String emoji, String title, String subtitle) {
    final selected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 90,
          decoration: BoxDecoration(
            color: selected ? AppTheme.brandGreen.withOpacity(0.15) : AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.brandGreen : AppTheme.borderDark,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(
              color: selected ? AppTheme.brandGreen : Colors.white,
              fontSize: 13, fontWeight: FontWeight.w700)),
            Text(subtitle, style: TextStyle(
              color: AppTheme.textSecondaryDark, fontSize: 10)),
          ]),
        ),
      ),
    );
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
      Text(label, style: const TextStyle(
        color: Colors.white, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: _deco(hint, icon),
        validator: validator ?? (v) {
          if (required && (v == null || v.isEmpty)) return 'Campo requerido';
          return null;
        },
      ),
    ]);
  }

  Widget _passwordField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('CONTRASEÑA', style: TextStyle(
      color: Colors.white, fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    const SizedBox(height: 8),
    TextFormField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _deco('••••••••', Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.textSecondaryDark, size: 20),
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
    const Text('CONFIRMAR CONTRASEÑA', style: TextStyle(
      color: Colors.white, fontSize: 11,
      fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    const SizedBox(height: 8),
    TextFormField(
      controller: _confirmCtrl,
      obscureText: _obscureConfirm,
      style: const TextStyle(color: Colors.white),
      decoration: _deco('••••••••', Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppTheme.textSecondaryDark, size: 20),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo requerido';
        if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
        return null;
      },
    ),
  ]);

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppTheme.textHintDark),
    prefixIcon: Icon(icon, color: AppTheme.textSecondaryDark, size: 18),
    filled: true,
    fillColor: AppTheme.cardDark,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.borderDark, width: 0.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.alertRedLight, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
