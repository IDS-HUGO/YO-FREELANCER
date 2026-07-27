// lib/features/services/data/repositories/node_service_repository_impl.dart
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_node_datasource.dart';

/// Implementación de [ServiceRepository] contra el backend propio (Node). Se
/// registra como el `ServiceRepository` principal en `injection.dart` cuando
/// `BackendModeConfig.current == BackendMode.ownBackend` (ver
/// docs/BACKEND_CONFIG.md).
class NodeServiceRepositoryImpl implements ServiceRepository {
  final ServiceNodeDataSource _dataSource;

  NodeServiceRepositoryImpl(this._dataSource);

  @override
  Future<List<ServiceEntity>> getAllServices({int limit = 20, int offset = 0}) =>
      _dataSource.getAllServices(limit: limit, offset: offset);

  @override
  Future<List<ServiceEntity>> getServicesByYoer(String yoerId) =>
      _dataSource.getServicesByYoer(yoerId);

  @override
  Future<ServiceEntity> getServiceById(String id) => _dataSource.getServiceById(id);

  @override
  Future<List<ServiceEntity>> getServicesByCategory(
    ServiceCategory category, {
    int limit = 20,
  }) =>
      _dataSource.getServicesByCategory(category, limit: limit);

  @override
  Future<List<ServiceEntity>> searchServices(String query) =>
      _dataSource.searchServices(query);

  @override
  Future<ServiceEntity> createService(ServiceEntity service) =>
      _dataSource.createService(service);

  @override
  Future<ServiceEntity> updateService(String id, ServiceEntity service) =>
      _dataSource.updateService(id, service);

  @override
  Future<void> deleteService(String id) => _dataSource.deleteService(id);

  @override
  Future<ServiceEntity> toggleServiceStatus(String id, bool isActive) =>
      _dataSource.toggleServiceStatus(id, isActive);

  @override
  Future<String> uploadServiceImage(String serviceId, String filePath) =>
      _dataSource.uploadServiceImage(serviceId, filePath);
}
