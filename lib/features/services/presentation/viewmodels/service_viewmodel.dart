// lib/features/services/presentation/viewmodels/service_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_entity.dart';
import '../../data/datasources/service_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Estado ────────────────────────────────────────────────────────────────────
class ServiceState {
  final bool isLoading;
  final List<ServiceEntity> services;
  final List<ServiceEntity> userServices;
  final List<ServiceEntity> searchResults;
  final List<ServiceEntity> filteredByCategory;
  final ServiceEntity? selectedService;
  final String? error;
  final String? successMessage;

  const ServiceState({
    this.isLoading = false,
    this.services = const [],
    this.userServices = const [],
    this.searchResults = const [],
    this.filteredByCategory = const [],
    this.selectedService,
    this.error,
    this.successMessage,
  });

  ServiceState copyWith({
    bool? isLoading,
    List<ServiceEntity>? services,
    List<ServiceEntity>? userServices,
    List<ServiceEntity>? searchResults,
    List<ServiceEntity>? filteredByCategory,
    ServiceEntity? selectedService,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearSelected = false,
  }) {
    return ServiceState(
      isLoading: isLoading ?? this.isLoading,
      services: services ?? this.services,
      userServices: userServices ?? this.userServices,
      searchResults: searchResults ?? this.searchResults,
      filteredByCategory: filteredByCategory ?? this.filteredByCategory,
      selectedService: clearSelected ? null : (selectedService ?? this.selectedService),
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class ServiceViewModel extends StateNotifier<ServiceState> {
  final ServiceRemoteDataSource _dataSource;

  ServiceViewModel(this._dataSource) : super(const ServiceState()) {
    getAllServices();
  }

  Future<void> getAllServices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final services = await _dataSource.getAllServices();
      state = state.copyWith(isLoading: false, services: services);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> getUserServices(String yoerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final services = await _dataSource.getServicesByYoer(yoerId);
      state = state.copyWith(isLoading: false, userServices: services);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> getServiceById(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final service = await _dataSource.getServiceById(id);
      state = state.copyWith(isLoading: false, selectedService: service);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> filterByCategory(ServiceCategory category) async {
    state = state.copyWith(isLoading: true);
    try {
      final services = await _dataSource.getServicesByCategory(category);
      state = state.copyWith(isLoading: false, filteredByCategory: services);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> searchServices(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(searchResults: []);
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final results = await _dataSource.searchServices(query);
      state = state.copyWith(isLoading: false, searchResults: results);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<bool> createService(ServiceEntity service) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _dataSource.createService(service);
      state = state.copyWith(
        isLoading: false,
        userServices: [created, ...state.userServices],
        successMessage: 'Servicio publicado exitosamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> updateService(String id, ServiceEntity service) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _dataSource.updateService(id, service);
      final userServices = state.userServices
          .map((s) => s.id == id ? updated : s)
          .toList();
      state = state.copyWith(
        isLoading: false,
        userServices: userServices,
        selectedService: updated,
        successMessage: 'Servicio actualizado',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
      return false;
    }
  }

  Future<bool> deleteService(String id) async {
    try {
      await _dataSource.deleteService(id);
      final userServices = state.userServices.where((s) => s.id != id).toList();
      state = state.copyWith(
        userServices: userServices,
        successMessage: 'Servicio eliminado',
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: _parseError(e));
      return false;
    }
  }

  Future<bool> toggleServiceStatus(String id) async {
    final current = state.userServices.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('Servicio no encontrado'),
    );
    try {
      final updated = await _dataSource.toggleServiceStatus(id, !current.isActive);
      final userServices = state.userServices
          .map((s) => s.id == id ? updated : s)
          .toList();
      state = state.copyWith(
        userServices: userServices,
        successMessage: updated.isActive ? 'Servicio activado' : 'Servicio desactivado',
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: _parseError(e));
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  void clearSelection() {
    state = state.copyWith(clearSelected: true);
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Sin conexión a internet.';
    }
    if (msg.contains('permission') || msg.contains('RLS')) {
      return 'No tienes permiso para realizar esta acción.';
    }
    return 'Error inesperado. Intenta de nuevo.';
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final serviceDataSourceProvider = Provider<ServiceRemoteDataSource>((ref) {
  return ServiceRemoteDataSource(Supabase.instance.client);
});

final serviceViewModelProvider =
    StateNotifierProvider<ServiceViewModel, ServiceState>((ref) {
  return ServiceViewModel(ref.read(serviceDataSourceProvider));
});
