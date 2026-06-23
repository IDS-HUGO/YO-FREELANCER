// lib/features/services/presentation/screens/create_service_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_theme.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Servicio publicado!'),
          backgroundColor: AppTheme.brandGreenDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else if (mounted) {
      final err = ref.read(serviceViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Error'), backgroundColor: AppTheme.alertRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
        ),
        title: const Text('Nuevo Servicio',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ── Título ────────────────────────────────────────────────────
            _label('TÍTULO DEL SERVICIO'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Ej: Desarrollo de App Android', Icons.title_rounded),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 18),

            // ── Descripción ───────────────────────────────────────────────
            _label('DESCRIPCIÓN'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Describe detalladamente tu servicio...', Icons.description_outlined),
              validator: (v) => (v == null || v.length < 20) ? 'Mínimo 20 caracteres' : null,
            ),
            const SizedBox(height: 18),

            // ── Categoría ─────────────────────────────────────────────────
            _label('CATEGORÍA'),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ServiceCategory.values.map((c) {
                  final sel = _category == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.brandGreen : AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? AppTheme.brandGreen : AppTheme.borderDark,
                          width: 0.5,
                        ),
                      ),
                      child: Text('${c.emoji} ${c.displayName}',
                          style: TextStyle(
                            color: sel ? Colors.white : AppTheme.textSecondaryDark,
                            fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // ── Tipo de servicio ──────────────────────────────────────────
            _label('TIPO DE SERVICIO'),
            const SizedBox(height: 10),
            Row(children: ServiceType.values.map((t) {
              final sel = _type == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.brandGreen.withValues(alpha: 0.15) : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppTheme.brandGreen : AppTheme.borderDark,
                        width: sel ? 1.5 : 0.5,
                      ),
                    ),
                    child: Text(t.displayName, textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sel ? AppTheme.brandGreen : AppTheme.textSecondaryDark,
                          fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                        )),
                  ),
                ),
              );
            }).toList()),
            const SizedBox(height: 18),

            // ── Precio y tipo ─────────────────────────────────────────────
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('PRECIO (MXN)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderDark, width: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PriceType>(
                      value: _priceType,
                      isExpanded: true,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      iconEnabledColor: AppTheme.textSecondaryDark,
                      items: PriceType.values.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName),
                      )).toList(),
                      onChanged: (v) { if (v != null) setState(() => _priceType = v); },
                    ),
                  ),
                ),
              ])),
            ]),
            const SizedBox(height: 18),

            // ── Ciudad ────────────────────────────────────────────────────
            _label('CIUDAD (OPCIONAL)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Ej: Ciudad de México', Icons.location_city_outlined),
            ),
            const SizedBox(height: 18),

            // ── Especialidades ────────────────────────────────────────────
            _label('ESPECIALIDADES (SEPARADAS POR COMA)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _specialtiesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _deco('Kotlin, Compose, Firebase', Icons.auto_awesome_outlined),
            ),
            const SizedBox(height: 36),

            // ── Botones ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
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
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.publish_rounded),
                        SizedBox(width: 8),
                        Text('Publicar Servicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ]),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppTheme.textSecondaryDark, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
        color: Colors.white, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 1.2,
      ));

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppTheme.textHintDark),
    prefixIcon: Icon(icon, color: AppTheme.textSecondaryDark, size: 18),
    filled: true,
    fillColor: AppTheme.cardDark,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderDark, width: 0.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.brandGreen, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.alertRedLight, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
