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

    final isVerified = state.profile?.isVerified == true;
    final isPending = state.profile?.verificationRequestedAt != null;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Modo Artista / Talento')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.isLoading
              ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
              : SingleChildScrollView(
                  key: const ValueKey('content'),
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Card(
                      color: isVerified ? context.colors.primaryContainer : context.card,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(children: [
                          Icon(
                            isVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
                            color: isVerified ? context.colors.primary : context.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                isVerified
                                    ? 'Tu cuenta está verificada como Artista/Talento'
                                    : isPending
                                        ? 'Tu verificación está en revisión'
                                        : 'Activa el modo Artista/Talento para destacar tu perfil',
                                key: ValueKey('$isVerified-$isPending'),
                                style: context.textTheme.bodyMedium?.copyWith(color: context.textPrimary),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    TextField(
                      controller: _stageNameCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre artístico'),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text('¿Quién administra tu perfil?',
                        style: context.textTheme.labelLarge?.copyWith(color: context.textSecondary)),
                    const SizedBox(height: AppSpacing.sm + 2),
                    SegmentedButton<ManagerType>(
                      segments: ManagerType.values
                          .map((m) => ButtonSegment(value: m, label: Text(m.displayName)))
                          .toList(),
                      selected: {_managerType},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) => setState(() => _managerType = selection.first),
                    ),

                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: _managerType == ManagerType.managed
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Column(children: [
                        const SizedBox(height: AppSpacing.xl),
                        TextField(
                          controller: _managerNameCtrl,
                          decoration: const InputDecoration(labelText: 'Nombre del manager'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          controller: _managerContactCtrl,
                          decoration: const InputDecoration(labelText: 'Contacto del manager'),
                        ),
                      ]),
                      secondChild: const SizedBox.shrink(),
                    ),

                    const SizedBox(height: AppSpacing.xxl),
                    FilledButton(
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
                    const SizedBox(height: AppSpacing.md),
                    if (!isVerified)
                      OutlinedButton(
                        onPressed: user == null || isPending
                            ? null
                            : () => ref.read(artistViewModelProvider.notifier).requestVerification(user.id),
                        child: Text(isPending ? 'Verificación en revisión' : 'Solicitar verificación'),
                      ),
                  ]),
                ),
        ),
      ),
    );
  }
}
