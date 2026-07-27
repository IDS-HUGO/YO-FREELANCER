// lib/features/services/presentation/screens/create_service_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/service_viewmodel.dart';
import '../../domain/entities/service_entity.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  const CreateServiceScreen({super.key});
  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _cityCtrl     = TextEditingController();
  final _specialtiesCtrl = TextEditingController();

  ServiceCategory _category  = ServiceCategory.tecnologia;
  ServiceType     _type      = ServiceType.local;
  PriceType       _priceType = PriceType.precioFijo;

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _cityCtrl.dispose(); _specialtiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final specialties = _specialtiesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final service = ServiceEntity(
      id: '',
      yoerId: user.id,
      yoerName: user.fullName,
      yoerImageUrl: user.profileImageUrl,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      specialties: specialties,
      serviceType: _type,
      priceType: _priceType,
      price: double.parse(_priceCtrl.text.trim()),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final ok = await ref.read(serviceViewModelProvider.notifier).createService(service);
    if (ok && mounted) {
      context.pop();
      showAppSnackBar(context, '¡Servicio publicado!');
    } else if (mounted) {
      final err = ref.read(serviceViewModelProvider).error;
      showAppErrorDialog(context, title: 'No se pudo publicar el servicio', message: err ?? 'Intenta de nuevo más tarde.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceViewModelProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: const Text('Nuevo Servicio'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          children: [
            // ── Título ────────────────────────────────────────────────────
            _label('TÍTULO DEL SERVICIO'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _titleCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: _deco('Ej: Desarrollo de App Android', Icons.title_rounded),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: AppSpacing.lg + 2),

            // ── Descripción ───────────────────────────────────────────────
            _label('DESCRIPCIÓN'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              style: TextStyle(color: context.textPrimary),
              decoration: _deco('Describe detalladamente tu servicio...', Icons.description_outlined),
              validator: (v) => (v == null || v.length < 20) ? 'Mínimo 20 caracteres' : null,
            ),
            const SizedBox(height: AppSpacing.lg + 2),

            // ── Categoría ─────────────────────────────────────────────────
            _label('CATEGORÍA'),
            const SizedBox(height: AppSpacing.sm + 2),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ServiceCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final c = ServiceCategory.values[i];
                  final sel = _category == c;
                  return ChoiceChip(
                    label: Text('${c.emoji} ${c.displayName}'),
                    selected: sel,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: context.colors.primary,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : context.textSecondary,
                      fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg + 2),

            // ── Tipo de servicio ──────────────────────────────────────────
            _label('TIPO DE SERVICIO'),
            const SizedBox(height: AppSpacing.sm + 2),
            Row(children: [
              Expanded(
                child: SegmentedButton<ServiceType>(
                  segments: ServiceType.values
                      .map((t) => ButtonSegment(value: t, label: Text(t.displayName)))
                      .toList(),
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                  showSelectedIcon: false,
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg + 2),

            // ── Precio y tipo ─────────────────────────────────────────────
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('PRECIO (MXN)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: context.textPrimary),
                  decoration: _deco('0.00', Icons.attach_money_rounded),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('TIPO DE PRECIO'),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<PriceType>(
                  initialValue: _priceType,
                  isExpanded: true,
                  dropdownColor: context.card,
                  style: TextStyle(color: context.textPrimary, fontSize: 13),
                  items: PriceType.values.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.displayName),
                  )).toList(),
                  onChanged: (v) { if (v != null) setState(() => _priceType = v); },
                ),
              ])),
            ]),
            const SizedBox(height: AppSpacing.lg + 2),

            // ── Ciudad ────────────────────────────────────────────────────
            _label('CIUDAD (OPCIONAL)'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _cityCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: _deco('Ej: Ciudad de México', Icons.location_city_outlined),
            ),
            const SizedBox(height: AppSpacing.lg + 2),

            // ── Especialidades ────────────────────────────────────────────
            _label('ESPECIALIDADES (SEPARADAS POR COMA)'),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _specialtiesCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: _deco('Kotlin, Compose, Firebase', Icons.auto_awesome_outlined),
            ),
            const SizedBox(height: AppSpacing.xxxl + 4),

            // ── Botones ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.isLoading ? null : _submit,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: state.isLoading
                      ? const SizedBox(key: ValueKey('loading'), width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Row(key: ValueKey('idle'), mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.publish_rounded),
                          SizedBox(width: AppSpacing.sm),
                          Text('Publicar Servicio'),
                        ]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.textSecondary,
                  side: BorderSide(color: context.border),
                ),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: context.textTheme.labelSmall?.copyWith(
        color: context.textPrimary, fontWeight: FontWeight.w700, letterSpacing: 1.2,
      ));

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18),
  );
}
