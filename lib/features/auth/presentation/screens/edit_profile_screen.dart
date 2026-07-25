// lib/features/auth/presentation/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../viewmodels/auth_viewmodel.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

const _genderOptions = ['Masculino', 'Femenino', 'Otro', 'Prefiero no decir'];

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _ageCtrl;
  String? _gender;
  String? _pendingImagePath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _ageCtrl = TextEditingController(text: user?.age?.toString() ?? '');
    _gender = (user?.gender != null && _genderOptions.contains(user!.gender)) ? user.gender : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _pendingImagePath = picked.path);
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _saving = true);

    String? imageUrl = user.profileImageUrl;
    if (_pendingImagePath != null) {
      imageUrl = await ref.read(authViewModelProvider.notifier).uploadProfileImage(_pendingImagePath!)
          ?? imageUrl;
    }

    final updated = user.copyWith(
      fullName: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      profileImageUrl: imageUrl,
      age: int.tryParse(_ageCtrl.text.trim()),
      gender: _gender,
    );

    final ok = await ref.read(authViewModelProvider.notifier).updateProfile(updated);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      showAppSnackBar(context, 'Perfil actualizado');
      Navigator.of(context).pop();
    } else {
      showAppSnackBar(context, 'No se pudo actualizar el perfil', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(children: [
                UserAvatar(
                  imageUrl: _pendingImagePath ?? user?.profileImageUrl,
                  initials: user?.initials ?? '?',
                  size: 96,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.brandGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Nombre completo'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityCtrl,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: 'Edad'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  dropdownColor: context.card,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(labelText: 'Género'),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _bioCtrl,
              maxLines: 4,
              style: TextStyle(color: context.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Semblanza / biografía',
                hintText: 'Ej: Soy artista del tatuaje especialista en realismo...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar cambios'),
            ),
          ]),
        ),
      ),
    );
  }
}
