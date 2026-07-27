// lib/features/auth/domain/repositories/kyc_repository.dart
import 'dart:io';
import '../entities/kyc_result.dart';
import '../../data/datasources/kyc_remote_datasource.dart';

/// Verificación facial de identidad (Tarea 2, ver docs/KYC.md).
///
/// A diferencia de [AuthRepository]/`ServiceRepository`, esta interfaz no
/// tiene una implementación de respaldo: si el microservicio de KYC no
/// responde, el registro **no se aprueba automáticamente** (fallo cerrado).
/// No hay "modo degradado" para la verificación de identidad.
abstract class KycRepository {
  Future<KycResult> verifyIdentity({
    required File idImage,
    required File selfieImage,
  });
}

class KycRepositoryImpl implements KycRepository {
  final KycRemoteDataSource _remoteDataSource;

  KycRepositoryImpl(this._remoteDataSource);

  @override
  Future<KycResult> verifyIdentity({
    required File idImage,
    required File selfieImage,
  }) {
    return _remoteDataSource.verifyIdentity(
      idImage: idImage,
      selfieImage: selfieImage,
    );
  }
}
