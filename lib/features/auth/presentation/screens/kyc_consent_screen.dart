// lib/features/auth/presentation/screens/kyc_consent_screen.dart
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';
import 'kyc_id_capture_screen.dart';

/// Primer paso del flujo de verificación facial (Tarea 2, ver docs/KYC.md).
/// Aplica tanto a YOER como a Cliente: nadie entra a la app sin completar
/// este flujo (o quedar en estado `rejected`/`error` con opción de reintentar).
class KycConsentScreen extends StatefulWidget {
  const KycConsentScreen({super.key});

  @override
  State<KycConsentScreen> createState() => _KycConsentScreenState();
}

class _KycConsentScreenState extends State<KycConsentScreen> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified_user_rounded, size: 56, color: context.colors.primary),
              const SizedBox(height: AppSpacing.xl),
              Text('Verifica tu identidad', style: context.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Antes de continuar necesitamos verificar tu identidad para '
                    'proteger a la comunidad de YO FREE-LANCER. Te pediremos:\n\n'
                    '1. Una foto de tu identificación oficial (INE o pasaporte).\n'
                    '2. Una selfie tuya en este momento.\n\n'
                    'Estas imágenes se procesan de forma automática para comparar '
                    'tu rostro con el de tu identificación y no se almacenan: se '
                    'procesan en memoria y se descartan de inmediato. Solo '
                    'conservamos el resultado (verificado / no verificado) '
                    'asociado a tu cuenta.\n\n'
                    'Puedes solicitar más información escribiendo a soporte.',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CheckboxListTile(
                value: _accepted,
                onChanged: (v) => setState(() => _accepted = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Acepto el tratamiento de mis datos biométricos para fines '
                  'de verificación de identidad.',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _accepted
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const KycIdCaptureScreen(),
                            ),
                          )
                      : null,
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
