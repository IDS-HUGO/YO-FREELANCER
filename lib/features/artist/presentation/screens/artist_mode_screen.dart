// lib/features/artist/presentation/screens/artist_mode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../data/datasources/artist_remote_datasource.dart';

class ArtistModeScreen extends ConsumerStatefulWidget {
  const ArtistModeScreen({super.key});
  @override
  ConsumerState<ArtistModeScreen> createState() => _ArtistModeScreenState();
}

class _ArtistModeScreenState extends ConsumerState<ArtistModeScreen> {
  final _stageNameCtrl = TextEditingController();
  final _managerNameCtrl = TextEditingController();
  final _managerContactCtrl = TextEditingController();
  ManagerType _managerType = ManagerType.self;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await ref.read(artistViewModelProvider.notifier).load(user.id);
        _hydrate();
      }
    });
  }

  void _hydrate() {
    final profile = ref.read(artistViewModelProvider).profile;
    if (profile != null && !_initialized) {
      _stageNameCtrl.text = profile.stageName ?? '';
      _managerNameCtrl.text = profile.managerName ?? '';
      _managerContactCtrl.text = profile.managerContact ?? '';
      _managerType = profile.managerType;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _stageNameCtrl.dispose();
    _managerNameCtrl.dispose();
    _managerContactCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(artistViewModelProvider);
    _hydrate();

    ref.listen(artistViewModelProvider, (prev, next) {
      if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        showAppSnackBar(context, next.successMessage!);
        ref.read(artistViewModelProvider.notifier).clearMessages();
      }
      if (next.error != null && next.error != prev?.error) {
        showAppSnackBar(context, next.error!, isError: true);
        ref.read(artistViewModelProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Modo Artista / Talento')),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: state.profile?.isVerified == true
                          ? AppTheme.brandGreen.withValues(alpha: 0.12)
                          : context.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: state.profile?.isVerified == true ? AppTheme.brandGreen : context.border,
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        state.profile?.isVerified == true ? Icons.verified_rounded : Icons.info_outline_rounded,
                        color: state.profile?.isVerified == true ? AppTheme.brandGreen : context.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.profile?.isVerified == true
                              ? 'Tu cuenta está verificada como Artista/Talento'
                              : state.profile?.verificationRequestedAt != null
                                  ? 'Tu verificación está en revisión'
                                  : 'Activa el modo Artista/Talento para destacar tu perfil',
                          style: TextStyle(color: context.textPrimary, fontSize: 12),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _stageNameCtrl,
                    style: TextStyle(color: context.textPrimary),
                    decoration: const InputDecoration(labelText: 'Nombre artístico'),
                  ),
                  const SizedBox(height: 20),

                  Text('¿Quién administra tu perfil?',
                      style: TextStyle(color: context.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(children: ManagerType.values.map((m) {
                    final selected = _managerType == m;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _managerType = m),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.brandGreen : context.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selected ? AppTheme.brandGreen : context.border),
                          ),
                          child: Text(m.displayName, textAlign: TextAlign.center,
                              style: TextStyle(color: selected ? Colors.white : context.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    );
                  }).toList()),

                  if (_managerType == ManagerType.managed) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _managerNameCtrl,
                      style: TextStyle(color: context.textPrimary),
                      decoration: const InputDecoration(labelText: 'Nombre del manager'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _managerContactCtrl,
                      style: TextStyle(color: context.textPrimary),
                      decoration: const InputDecoration(labelText: 'Contacto del manager'),
                    ),
                  ],

                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: user == null
                        ? null
                        : () => ref.read(artistViewModelProvider.notifier).save(
                              user.id,
                              stageName: _stageNameCtrl.text.trim().isEmpty ? null : _stageNameCtrl.text.trim(),
                              managerType: _managerType,
                              managerName: _managerNameCtrl.text.trim().isEmpty ? null : _managerNameCtrl.text.trim(),
                              managerContact: _managerContactCtrl.text.trim().isEmpty ? null : _managerContactCtrl.text.trim(),
                            ),
                    child: const Text('Guardar'),
                  ),
                  const SizedBox(height: 12),
                  if (state.profile?.isVerified != true)
                    OutlinedButton(
                      onPressed: user == null || state.profile?.verificationRequestedAt != null
                          ? null
                          : () => ref.read(artistViewModelProvider.notifier).requestVerification(user.id),
                      child: Text(state.profile?.verificationRequestedAt != null
                          ? 'Verificación en revisión'
                          : 'Solicitar verificación'),
                    ),
                ]),
              ),
      ),
    );
  }
}
