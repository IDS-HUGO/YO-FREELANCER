// lib/features/auth/presentation/screens/kyc_id_capture_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/file_upload_validator.dart';
import '../../../../shared/widgets/main_scaffold.dart';
import 'kyc_selfie_capture_screen.dart';

/// Segundo paso del flujo de KYC: fotografiar la identificación oficial
/// (INE o pasaporte). Primer consumidor real de `image_cropper` y
/// `permission_handler` en la app (ver docs/KYC.md).
class KycIdCaptureScreen extends StatefulWidget {
  const KycIdCaptureScreen({super.key});

  @override
  State<KycIdCaptureScreen> createState() => _KycIdCaptureScreenState();
}

class _KycIdCaptureScreenState extends State<KycIdCaptureScreen> {
  String? _imagePath;
  bool _busy = false;

  Future<void> _capture() async {
    setState(() => _busy = true);
    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        if (mounted) {
          showAppSnackBar(
            context,
            'Necesitamos acceso a la cámara para fotografiar tu identificación.',
            isError: true,
          );
        }
        return;
      }

      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
      );
      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
      );
      if (cropped == null) return;

      final file = File(cropped.path);
      await FileUploadValidator.validateImageFile(file);
      setState(() => _imagePath = cropped.path);
    } on FileValidationException catch (e) {
      if (mounted) showAppSnackBar(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'No se pudo capturar la foto. Intenta de nuevo.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(title: const Text('Tu identificación')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Text(
                'Fotografía tu INE o pasaporte. Asegúrate de que se vea completo, '
                'sin reflejos y que el texto sea legible.',
                style: context.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.card,
                    borderRadius: AppRadius.lgR,
                    border: Border.all(color: context.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imagePath != null
                      ? Image.file(File(_imagePath!), fit: BoxFit.contain)
                      : Center(
                          child: Icon(
                            Icons.badge_outlined,
                            size: 64,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _capture,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: Text(_imagePath == null ? 'Tomar foto' : 'Tomar otra foto'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _imagePath == null
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KycSelfieCaptureScreen(idImagePath: _imagePath!),
                            ),
                          ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
