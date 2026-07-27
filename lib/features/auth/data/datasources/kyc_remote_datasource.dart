// lib/features/auth/data/datasources/kyc_remote_datasource.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../app/config/kyc_config.dart';
import '../../domain/entities/kyc_result.dart';

/// Cliente HTTP hacia el microservicio de verificación facial
/// (`kyc-service/`, FastAPI + DeepFace). Ver docs/KYC.md para el contrato
/// completo de fallo cerrado.
class KycRemoteDataSource {
  final Dio _dio;

  KycRemoteDataSource({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: KycConfig.baseUrl,
              connectTimeout: KycConfig.requestTimeout,
              receiveTimeout: KycConfig.requestTimeout,
              sendTimeout: KycConfig.requestTimeout,
            ));

  /// Envía la identificación oficial y la selfie al microservicio de
  /// verificación. **Nunca** interpreta una excepción o respuesta no-2xx
  /// como verificado — ver `KycRepository.verifyIdentity` para el contrato
  /// de fallo cerrado completo.
  Future<KycResult> verifyIdentity({
    required File idImage,
    required File selfieImage,
  }) async {
    try {
      final formData = FormData.fromMap({
        'id_document': await MultipartFile.fromFile(idImage.path),
        'selfie': await MultipartFile.fromFile(selfieImage.path),
      });

      final response = await _dio.post(KycConfig.verifyPath, data: formData);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return KycResult.error();
      }

      final match = data['match'] as bool? ?? false;
      final requestId = data['request_id'] as String?;
      final similarity = (data['similarity'] as num?)?.toDouble();

      if (!match) {
        return KycResult.rejected(requestId: requestId, similarity: similarity);
      }
      return KycResult.verified(
        requestId: requestId ?? '',
        similarity: similarity ?? 0.0,
      );
    } on DioException catch (e) {
      // Cualquier error de red, timeout, o respuesta de error del servicio
      // (4xx/5xx) se trata como "no verificado", nunca como verificado.
      final statusCode = e.response?.statusCode;
      if (statusCode == 422) {
        final data = e.response?.data;
        final message = data is Map<String, dynamic> ? data['message'] as String? : null;
        return KycResult.rejected(message: message);
      }
      return KycResult.error();
    } catch (_) {
      return KycResult.error();
    }
  }
}
