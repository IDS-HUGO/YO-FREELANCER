// lib/features/services/domain/repositories/service_repository.dart
import '../entities/service_entity.dart';
import '../../data/datasources/service_remote_datasource.dart';

/// Interfaz para las operaciones de "proyectos" (tabla `services`).
///
/// Introducida para que el resto de la app dependa de esta interfaz en vez
/// de llamar a Supabase directamente — así se puede elegir en tiempo de
/// build si la implementación real es Supabase o el backend propio (ver
/// `lib/app/config/backend_mode.dart` y docs/BACKEND_CONFIG.md). Espeja 1:1
/// los métodos que ya existían en `ServiceRemoteDataSource`, así que la
/// implementación de Supabase no cambia ningún comportamiento.
abstract class ServiceRepository {
  Future<List<ServiceEntity>> getAllServices({int limit = 20, int offset = 0});
  Future<List<ServiceEntity>> getServicesByYoer(String yoerId);
  Future<ServiceEntity> getServiceById(String id);
  Future<List<ServiceEntity>> getServicesByCategory(
    ServiceCategory category, {
    int limit = 20,
  });
  Future<List<ServiceEntity>> searchServices(String query);
  Future<ServiceEntity> createService(ServiceEntity service);
  Future<ServiceEntity> updateService(String id, ServiceEntity service);
  Future<void> deleteService(String id);
  Future<ServiceEntity> toggleServiceStatus(String id, bool isActive);
  Future<String> uploadServiceImage(String serviceId, String filePath);
}

/// ─── Implementación con Supabase ──────────────────────────────────────────
/// Delegación directa al datasource existente: cero cambio de comportamiento.
class SupabaseServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource _remoteDataSource;

  SupabaseServiceRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ServiceEntity>> getAllServices({int limit = 20, int offset = 0}) =>
      _remoteDataSource.getAllServices(limit: limit, offset: offset);

  @override
  Future<List<ServiceEntity>> getServicesByYoer(String yoerId) =>
      _remoteDataSource.getServicesByYoer(yoerId);

  @override
  Future<ServiceEntity> getServiceById(String id) =>
      _remoteDataSource.getServiceById(id);

  @override
  Future<List<ServiceEntity>> getServicesByCategory(
    ServiceCategory category, {
    int limit = 20,
  }) =>
      _remoteDataSource.getServicesByCategory(category, limit: limit);

  @override
  Future<List<ServiceEntity>> searchServices(String query) =>
      _remoteDataSource.searchServices(query);

  @override
  Future<ServiceEntity> createService(ServiceEntity service) =>
      _remoteDataSource.createService(service);

  @override
  Future<ServiceEntity> updateService(String id, ServiceEntity service) =>
      _remoteDataSource.updateService(id, service);

  @override
  Future<void> deleteService(String id) => _remoteDataSource.deleteService(id);

  @override
  Future<ServiceEntity> toggleServiceStatus(String id, bool isActive) =>
      _remoteDataSource.toggleServiceStatus(id, isActive);

  @override
  Future<String> uploadServiceImage(String serviceId, String filePath) =>
      _remoteDataSource.uploadServiceImage(serviceId, filePath);
}
