// lib/features/auth/presentation/screens/kyc_selfie_capture_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/file_upload_validator.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/kyc_viewmodel.dart';

/// Último paso del flujo de KYC: selfie + envío al microservicio de
/// verificación (ver docs/KYC.md). Sin cropper, a diferencia de la captura
/// de identificación — se mantiene simple en esta primera versión.
class KycSelfieCaptureScreen extends ConsumerStatefulWidget {
  final String idImagePath;
  const KycSelfieCaptureScreen({super.key, required this.idImagePath});

  @override
  ConsumerState<KycSelfieCaptureScreen> createState() => _KycSelfieCaptureScreenState();
}

class _KycSelfieCaptureScreenState extends ConsumerState<KycSelfieCaptureScreen> {
  String? _selfiePath;
  bool _busy = false;

  Future<void> _capture() async {
    setState(() => _busy = true);
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        if (mounted) {
          showAppSnackBar(context, 'Necesitamos acceso a la cámara para tu selfie.', isError: true);
        }
        return;
      }

      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 90,
      );
      if (picked == null) return;

      final file = File(picked.path);
      await FileUploadValidator.validateImageFile(file);
      setState(() => _selfiePath = picked.path);
    } on FileValidationException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'No se pudo capturar la selfie. Intenta de nuevo.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_selfiePath == null) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final result = await ref.read(kycViewModelProvider.notifier).submit(
          idImage: File(widget.idImagePath),
          selfieImage: File(_selfiePath!),
        );

    // Persistimos el resultado en el perfil sin importar si fue verificado,
    // rechazado o hubo un error (fallo cerrado: nunca queda "verified" por
    // omisión, ver KycResult/docs/KYC.md).
    await ref.read(authViewModelProvider.notifier).updateProfile(
          user.copyWith(kycStatus: result.status),
        );

    if (!mounted) return;

    if (result.isVerified) {
      showAppSnackBar(context, '¡Identidad verificada!');
      // El redirect del router se encarga de sacarnos de /kyc automáticamente
      // al detectar kycStatus == verified.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      await showAppErrorDialog(
        context,
        title: 'No se pudo verificar tu identidad',
        message: result.userMessage ?? 'Intenta de nuevo con mejor iluminación.',
      );
      // Volver a la captura de identificación para reintentar.
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(kycViewModelProvider).isSubmitting;

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Ahora tu selfie')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Text(
                'Toma una selfie con buena luz, mirando directo a la cámara, sin '
                'lentes oscuros ni cubrebocas.',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.lgR,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: context.card, border: Border.all(color: context.border)),
                    child: _selfiePath != null
                        ? Image.file(File(_selfiePath!), fit: BoxFit.cover)
                        : Center(
                            child: Icon(
                              Icons.face_retouching_natural_rounded,
                              size: 64,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy || isSubmitting ? null : _capture,
                  icon: const Icon(Icons.camera_front_rounded),
                  label: Text(_selfiePath == null ? 'Tomar selfie' : 'Tomar otra selfie'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_selfiePath == null || isSubmitting) ? null : _submit,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSubmitting
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Enviar verificación', key: ValueKey('label')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
