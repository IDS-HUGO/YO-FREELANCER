// lib/features/services/data/datasources/service_node_datasource.dart
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../app/config/backend_config.dart';
import '../../../../shared/dto/service_dto.dart';
import '../../domain/entities/service_entity.dart';

/// Cliente HTTP hacia el backend propio (Node) para "proyectos" (tabla
/// `services`), usado cuando `BackendModeConfig.current == BackendMode.ownBackend`.
/// Ver `AuthNodeDataSource` para el manejo de sesión compartido — este
/// datasource recibe el token vigente por parámetro en cada llamada en vez
/// de gestionarlo él mismo, porque las operaciones de servicios no inician
/// sesión por sí solas.
class ServiceNodeDataSource {
  final Dio _dio;
  final Future<String?> Function() _tokenProvider;

  ServiceNodeDataSource({
    required Future<String?> Function() tokenProvider,
    Dio? dio,
  })  : _tokenProvider = tokenProvider,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: BackendConfig.nodeBaseUrl,
              connectTimeout: BackendConfig.requestTimeout,
              receiveTimeout: BackendConfig.requestTimeout,
            ));

  Future<Options> _authOptions() async {
    final token = await _tokenProvider();
    return Options(headers: token != null ? {'Authorization': 'Bearer $token'} : null);
  }

  Future<List<ServiceEntity>> getAllServices({int limit = 20, int offset = 0}) async {
    final response = await _dio.get(
      BackendConfig.servicesPath,
      queryParameters: {'limit': limit, 'offset': offset},
      options: await _authOptions(),
    );
    return (response.data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<List<ServiceEntity>> getServicesByYoer(String yoerId) async {
    final response = await _dio.get(
      BackendConfig.servicesPath,
      queryParameters: {'yoer_id': yoerId},
      options: await _authOptions(),
    );
    return (response.data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<ServiceEntity> getServiceById(String id) async {
    final response = await _dio.get(
      BackendConfig.servicePath(id),
      options: await _authOptions(),
    );
    return ServiceDto.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  Future<List<ServiceEntity>> getServicesByCategory(
    ServiceCategory category, {
    int limit = 20,
  }) async {
    final response = await _dio.get(
      BackendConfig.servicesPath,
      queryParameters: {'category': category.name, 'limit': limit},
      options: await _authOptions(),
    );
    return (response.data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<List<ServiceEntity>> searchServices(String query) async {
    final response = await _dio.get(
      BackendConfig.servicesPath,
      queryParameters: {'search': query},
      options: await _authOptions(),
    );
    return (response.data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  Future<ServiceEntity> createService(ServiceEntity service) async {
    final dto = ServiceDto(
      id: '',
      yoerId: service.yoerId,
      title: service.title,
      description: service.description,
      category: service.category.name,
      specialties: service.specialties,
      serviceType: service.serviceType.name,
      priceType: service.priceType.name,
      price: service.price,
      currency: service.currency,
      latitude: service.latitude,
      longitude: service.longitude,
      address: service.address,
      city: service.city,
      images: service.images,
      videos: service.videos,
      requirements: service.requirements,
      includedItems: service.includedItems,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    final response = await _dio.post(
      BackendConfig.servicesPath,
      data: dto.toJson(),
      options: await _authOptions(),
    );
    return ServiceDto.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  Future<ServiceEntity> updateService(String id, ServiceEntity service) async {
    final response = await _dio.patch(
      BackendConfig.servicePath(id),
      data: {
        'title': service.title,
        'description': service.description,
        'category': service.category.name,
        'specialties': service.specialties,
        'service_type': service.serviceType.name,
        'price_type': service.priceType.name,
        'price': service.price,
        'is_active': service.isActive,
        'requirements': service.requirements,
        'included_items': service.includedItems,
      },
      options: await _authOptions(),
    );
    return ServiceDto.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  Future<void> deleteService(String id) async {
    await _dio.delete(BackendConfig.servicePath(id), options: await _authOptions());
  }

  Future<ServiceEntity> toggleServiceStatus(String id, bool isActive) async {
    final response = await _dio.patch(
      BackendConfig.serviceToggleStatusPath(id),
      data: {'is_active': isActive},
      options: await _authOptions(),
    );
    return ServiceDto.fromJson(response.data as Map<String, dynamic>).toEntity();
  }

  Future<String> uploadServiceImage(String serviceId, String filePath) async {
    final file = File(filePath);
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '${BackendConfig.servicePath(serviceId)}/image',
      data: formData,
      options: await _authOptions(),
    );
    return (response.data as Map<String, dynamic>)['url'] as String;
  }
}
