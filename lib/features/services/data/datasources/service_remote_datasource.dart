// lib/features/services/data/datasources/service_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../../shared/dto/service_dto.dart';
import '../../domain/entities/service_entity.dart';

class ServiceRemoteDataSource {
  final SupabaseClient _client;

  ServiceRemoteDataSource(this._client);

  // ── Obtener todos los servicios activos ───────────────────────────────────
  Future<List<ServiceEntity>> getAllServices({
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .select('*, profiles(full_name, profile_image_url, rating)')
        .eq('is_active', true)
        .order('is_promoted', ascending: false)
        .order('rating', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  // ── Servicios de un YOER ──────────────────────────────────────────────────
  Future<List<ServiceEntity>> getServicesByYoer(String yoerId) async {
    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .select('*, profiles(full_name, profile_image_url, rating)')
        .eq('yoer_id', yoerId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  // ── Servicio por ID ───────────────────────────────────────────────────────
  Future<ServiceEntity> getServiceById(String id) async {
    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .select('*, profiles(full_name, profile_image_url, rating)')
        .eq('id', id)
        .single();

    // Incrementar vistas
    _client.from(SupabaseConfig.servicesTable).update(
      {'views_count': (data['views_count'] as int? ?? 0) + 1},
    ).eq('id', id).then((_) {});

    return ServiceDto.fromJson(data).toEntity();
  }

  // ── Servicios por categoría ───────────────────────────────────────────────
  Future<List<ServiceEntity>> getServicesByCategory(
    ServiceCategory category, {
    int limit = 20,
  }) async {
    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .select('*, profiles(full_name, profile_image_url, rating)')
        .eq('is_active', true)
        .eq('category', category.name)
        .order('rating', ascending: false)
        .limit(limit);

    return (data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  // ── Búsqueda full-text ────────────────────────────────────────────────────
  Future<List<ServiceEntity>> searchServices(String query) async {
    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .select('*, profiles(full_name, profile_image_url, rating)')
        .eq('is_active', true)
        .or('title.ilike.%$query%,description.ilike.%$query%')
        .order('rating', ascending: false)
        .limit(30);

    return (data as List)
        .map((e) => ServiceDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  // ── Crear servicio ────────────────────────────────────────────────────────
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

    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .insert(dto.toJson())
        .select('*, profiles(full_name, profile_image_url, rating)')
        .single();

    return ServiceDto.fromJson(data).toEntity();
  }

  // ── Actualizar servicio ───────────────────────────────────────────────────
  Future<ServiceEntity> updateService(String id, ServiceEntity service) async {
    final updates = {
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
      'updated_at': DateTime.now().toIso8601String(),
    };

    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .update(updates)
        .eq('id', id)
        .select('*, profiles(full_name, profile_image_url, rating)')
        .single();

    return ServiceDto.fromJson(data).toEntity();
  }

  // ── Eliminar servicio ─────────────────────────────────────────────────────
  Future<void> deleteService(String id) async {
    await _client
        .from(SupabaseConfig.servicesTable)
        .delete()
        .eq('id', id);
  }

  // ── Toggle activo/inactivo ────────────────────────────────────────────────
  Future<ServiceEntity> toggleServiceStatus(String id, bool isActive) async {
    final data = await _client
        .from(SupabaseConfig.servicesTable)
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select('*, profiles(full_name, profile_image_url, rating)')
        .single();

    return ServiceDto.fromJson(data).toEntity();
  }

  // ── Subir imagen de servicio ──────────────────────────────────────────────
  Future<String> uploadServiceImage(String serviceId, String filePath) async {
    import 'dart:io';
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final path = '$serviceId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage
        .from(SupabaseConfig.serviceImagesBucket)
        .upload(path, file, fileOptions: const FileOptions(upsert: false));

    return _client.storage
        .from(SupabaseConfig.serviceImagesBucket)
        .getPublicUrl(path);
  }
}
