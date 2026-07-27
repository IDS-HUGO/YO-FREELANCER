// lib/features/auth/domain/entities/kyc_result.dart
import 'user_entity.dart';

/// Resultado de un intento de verificación facial (ver kyc-service/README.md).
///
/// Contrato "fail closed" (ver docs/KYC.md): [KycRepository.verifyIdentity]
/// nunca produce [KycStatus.verified] salvo que el microservicio haya
/// respondido 2xx con `match: true`. Cualquier error, timeout o `match:
/// false` se traduce a [KycStatus.rejected] o [KycStatus.error], nunca a
/// verificado por omisión.
class KycResult {
  final KycStatus status;
  final String? requestId;
  final double? similarity;
  final String? userMessage;

  const KycResult({
    required this.status,
    this.requestId,
    this.similarity,
    this.userMessage,
  });

  bool get isVerified => status == KycStatus.verified;

  factory KycResult.verified({required String requestId, required double similarity}) =>
      KycResult(status: KycStatus.verified, requestId: requestId, similarity: similarity);

  factory KycResult.rejected({String? requestId, double? similarity, String? message}) =>
      KycResult(
        status: KycStatus.rejected,
        requestId: requestId,
        similarity: similarity,
        userMessage: message ??
            'No pudimos confirmar que el rostro de tu selfie coincide con tu identificación. Intenta de nuevo con fotos más claras.',
      );

  factory KycResult.error([String? message]) => KycResult(
        status: KycStatus.error,
        userMessage: message ??
            'No pudimos completar la verificación en este momento. Intenta de nuevo en unos minutos.',
      );
}
