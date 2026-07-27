// lib/features/auth/presentation/viewmodels/kyc_viewmodel.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/kyc_result.dart';
import '../../domain/repositories/kyc_repository.dart';

// ── Estado ────────────────────────────────────────────────────────────────────
class KycState {
  final bool isSubmitting;
  final KycResult? result;

  const KycState({this.isSubmitting = false, this.result});

  KycState copyWith({bool? isSubmitting, KycResult? result, bool clearResult = false}) {
    return KycState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
/// Orquesta el paso de verificación facial del registro (Tarea 2, ver
/// docs/KYC.md). No tiene modo de respaldo: si el microservicio no responde,
/// [KycRepository.verifyIdentity] ya devuelve un [KycResult] en estado
/// `error`/`rejected` (fallo cerrado) — este ViewModel solo expone ese
/// resultado al UI, nunca lo convierte en "verificado" por su cuenta.
class KycViewModel extends StateNotifier<KycState> {
  final KycRepository _repository;

  KycViewModel(this._repository) : super(const KycState());

  Future<KycResult> submit({
    required File idImage,
    required File selfieImage,
  }) async {
    state = state.copyWith(isSubmitting: true, clearResult: true);
    final result = await _repository.verifyIdentity(
      idImage: idImage,
      selfieImage: selfieImage,
    );
    state = state.copyWith(isSubmitting: false, result: result);
    return result;
  }

  void reset() => state = const KycState();
}

// ── Providers ─────────────────────────────────────────────────────────────────
final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return getIt<KycRepository>();
});

final kycViewModelProvider = StateNotifierProvider<KycViewModel, KycState>((ref) {
  return KycViewModel(ref.read(kycRepositoryProvider));
});
