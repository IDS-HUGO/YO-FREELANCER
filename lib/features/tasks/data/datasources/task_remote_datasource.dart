// lib/features/tasks/data/datasources/task_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../services/domain/entities/service_entity.dart' show ServiceCategory;

enum TaskMode {
  expres, agendado;

  String get name => this == expres ? 'EXPRES' : 'AGENDADO';
  String get displayName => this == expres ? 'Exprés' : 'Agendado';

  static TaskMode fromRaw(String raw) => raw == 'AGENDADO' ? agendado : expres;
}

enum TaskServiceMode {
  presencial, enLinea, hibrida;

  String get name {
    switch (this) {
      case TaskServiceMode.presencial: return 'PRESENCIAL';
      case TaskServiceMode.enLinea:    return 'EN_LINEA';
      case TaskServiceMode.hibrida:    return 'HIBRIDA';
    }
  }

  String get displayName {
    switch (this) {
      case TaskServiceMode.presencial: return 'Presencial';
      case TaskServiceMode.enLinea:    return 'En línea';
      case TaskServiceMode.hibrida:    return 'Híbrida';
    }
  }

  static TaskServiceMode fromRaw(String raw) {
    const map = {'PRESENCIAL': presencial, 'EN_LINEA': enLinea, 'HIBRIDA': hibrida};
    return map[raw] ?? presencial;
  }
}

enum TaskRequestStatus {
  abierta, asignada, cancelada, completada;

  String get name {
    switch (this) {
      case TaskRequestStatus.abierta:    return 'ABIERTA';
      case TaskRequestStatus.asignada:   return 'ASIGNADA';
      case TaskRequestStatus.cancelada:  return 'CANCELADA';
      case TaskRequestStatus.completada: return 'COMPLETADA';
    }
  }

  String get displayName {
    switch (this) {
      case TaskRequestStatus.abierta:    return 'Abierta';
      case TaskRequestStatus.asignada:   return 'Asignada';
      case TaskRequestStatus.cancelada:  return 'Cancelada';
      case TaskRequestStatus.completada: return 'Completada';
    }
  }

  static TaskRequestStatus fromRaw(String raw) {
    const map = {
      'ABIERTA': abierta, 'ASIGNADA': asignada,
      'CANCELADA': cancelada, 'COMPLETADA': completada,
    };
    return map[raw] ?? abierta;
  }
}

enum ApplicationTarget {
  taskRequest, urgentTask;

  String get name => this == taskRequest ? 'TASK_REQUEST' : 'URGENT_TASK';
  static ApplicationTarget fromRaw(String raw) => raw == 'URGENT_TASK' ? urgentTask : taskRequest;
}

enum ApplicationStatus {
  pendiente, aceptada, rechazada;

  String get name {
    switch (this) {
      case ApplicationStatus.pendiente: return 'PENDIENTE';
      case ApplicationStatus.aceptada:  return 'ACEPTADA';
      case ApplicationStatus.rechazada: return 'RECHAZADA';
    }
  }

  String get displayName {
    switch (this) {
      case ApplicationStatus.pendiente: return 'Pendiente';
      case ApplicationStatus.aceptada:  return 'Aceptada';
      case ApplicationStatus.rechazada: return 'Rechazada';
    }
  }

  static ApplicationStatus fromRaw(String raw) {
    const map = {'PENDIENTE': pendiente, 'ACEPTADA': aceptada, 'RECHAZADA': rechazada};
    return map[raw] ?? pendiente;
  }
}

class UrgentTaskEntity {
  final String id;
  final String clientId;
  final String title;
  final String description;
  final ServiceCategory category;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? maxPrice;
  final bool isActive;
  final int applicantsCount;
  final String? assignedYoerId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final double? distanceKm;

  const UrgentTaskEntity({
    required this.id,
    required this.clientId,
    required this.title,
    required this.description,
    required this.category,
    this.latitude,
    this.longitude,
    this.address,
    this.maxPrice,
    this.isActive = true,
    this.applicantsCount = 0,
    this.assignedYoerId,
    required this.createdAt,
    required this.expiresAt,
    this.distanceKm,
  });

  factory UrgentTaskEntity.fromJson(Map<String, dynamic> json, {double? distanceKm}) {
    return UrgentTaskEntity(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ServiceCategory.otros,
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      applicantsCount: json['applicants_count'] as int? ?? 0,
      assignedYoerId: json['assigned_yoer_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      distanceKm: distanceKm,
    );
  }
}

class TaskRequestEntity {
  final String id;
  final String clientId;
  final String? clientName;
  final String title;
  final String description;
  final ServiceCategory category;
  final TaskMode mode;
  final TaskServiceMode serviceMode;
  final double? estimatedHours;
  final double budget;
  final String currency;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<String> scheduledDates;
  final TaskRequestStatus status;
  final String? assignedYoerId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const TaskRequestEntity({
    required this.id,
    required this.clientId,
    this.clientName,
    required this.title,
    required this.description,
    required this.category,
    required this.mode,
    required this.serviceMode,
    this.estimatedHours,
    required this.budget,
    this.currency = 'MXN',
    this.address,
    this.latitude,
    this.longitude,
    this.scheduledDates = const [],
    required this.status,
    this.assignedYoerId,
    required this.createdAt,
    this.expiresAt,
  });

  factory TaskRequestEntity.fromJson(Map<String, dynamic> json) {
    final clientProfile = json['client_profile'] as Map<String, dynamic>?;
    return TaskRequestEntity(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      clientName: clientProfile?['full_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ServiceCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ServiceCategory.otros,
      ),
      mode: TaskMode.fromRaw(json['mode'] as String? ?? 'EXPRES'),
      serviceMode: TaskServiceMode.fromRaw(json['service_mode'] as String? ?? 'PRESENCIAL'),
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
      budget: (json['budget'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      scheduledDates: (json['scheduled_dates'] as List? ?? []).map((e) => e.toString()).toList(),
      status: TaskRequestStatus.fromRaw(json['status'] as String? ?? 'ABIERTA'),
      assignedYoerId: json['assigned_yoer_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
    );
  }
}

class TaskApplicationEntity {
  final String id;
  final ApplicationTarget targetType;
  final String? taskRequestId;
  final String? urgentTaskId;
  final String yoerId;
  final String? yoerName;
  final String? yoerImageUrl;
  final double? yoerRating;
  final String? proposal;
  final double? proposedPrice;
  final ApplicationStatus status;
  final DateTime createdAt;

  const TaskApplicationEntity({
    required this.id,
    required this.targetType,
    this.taskRequestId,
    this.urgentTaskId,
    required this.yoerId,
    this.yoerName,
    this.yoerImageUrl,
    this.yoerRating,
    this.proposal,
    this.proposedPrice,
    required this.status,
    required this.createdAt,
  });

  factory TaskApplicationEntity.fromJson(Map<String, dynamic> json) {
    final yoerProfile = json['yoer_profile'] as Map<String, dynamic>?;
    return TaskApplicationEntity(
      id: json['id'] as String,
      targetType: ApplicationTarget.fromRaw(json['target_type'] as String? ?? 'TASK_REQUEST'),
      taskRequestId: json['task_request_id'] as String?,
      urgentTaskId: json['urgent_task_id'] as String?,
      yoerId: json['yoer_id'] as String,
      yoerName: yoerProfile?['full_name'] as String?,
      yoerImageUrl: yoerProfile?['profile_image_url'] as String?,
      yoerRating: (yoerProfile?['rating'] as num?)?.toDouble(),
      proposal: json['proposal'] as String?,
      proposedPrice: (json['proposed_price'] as num?)?.toDouble(),
      status: ApplicationStatus.fromRaw(json['status'] as String? ?? 'PENDIENTE'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class TaskRemoteDataSource {
  final SupabaseClient _client;
  TaskRemoteDataSource(this._client);

  static const _applicationSelectWithYoer = '''
    *,
    yoer_profile:profiles!task_applications_yoer_id_fkey(full_name, profile_image_url, rating)
  ''';

  // ── Urgent tasks (Radar) ──────────────────────────────────────────────────
  Future<List<UrgentTaskEntity>> getNearbyUrgentTasks({double? lat, double? lng, double radiusKm = 50}) async {
    if (lat != null && lng != null) {
      final ranked = await _client.rpc('get_nearby_urgent_tasks', params: {
        'user_lat': lat, 'user_lng': lng, 'radius_km': radiusKm, 'lim': 30,
      }) as List;
      if (ranked.isEmpty) return [];

      final ids = ranked.map((e) => e['id'] as String).toList();
      final distanceById = {for (final e in ranked) e['id'] as String: (e['distance_km'] as num).toDouble()};

      final data = await _client
          .from(SupabaseConfig.urgentTasksTable)
          .select()
          .inFilter('id', ids)
          .eq('is_active', true);

      final list = (data as List)
          .map((e) => UrgentTaskEntity.fromJson(e as Map<String, dynamic>, distanceKm: distanceById[e['id']]))
          .toList();
      list.sort((a, b) => (a.distanceKm ?? 999999).compareTo(b.distanceKm ?? 999999));
      return list;
    }

    final data = await _client
        .from(SupabaseConfig.urgentTasksTable)
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(30);

    return (data as List).map((e) => UrgentTaskEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Task requests (Expres / Agendado del cliente) ─────────────────────────
  Future<TaskRequestEntity> createTaskRequest({
    required String clientId,
    required String title,
    required String description,
    required ServiceCategory category,
    required TaskMode mode,
    required TaskServiceMode serviceMode,
    required double budget,
    double? estimatedHours,
    String? address,
    double? latitude,
    double? longitude,
    List<String> scheduledDates = const [],
  }) async {
    final data = await _client.from(SupabaseConfig.taskRequestsTable).insert({
      'client_id': clientId,
      'title': title,
      'description': description,
      'category': category.name,
      'mode': mode.name,
      'service_mode': serviceMode.name,
      'budget': budget,
      if (estimatedHours != null) 'estimated_hours': estimatedHours,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'scheduled_dates': scheduledDates,
    }).select().single();

    return TaskRequestEntity.fromJson(data);
  }

  Future<List<TaskRequestEntity>> getMyTaskRequests(String clientId) async {
    final data = await _client
        .from(SupabaseConfig.taskRequestsTable)
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => TaskRequestEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TaskRequestEntity>> getOpenTaskRequests({ServiceCategory? category}) async {
    var query = _client
        .from(SupabaseConfig.taskRequestsTable)
        .select('*, client_profile:profiles!task_requests_client_id_fkey(full_name)')
        .eq('status', 'ABIERTA');

    if (category != null) query = query.eq('category', category.name);

    final data = await query.order('created_at', ascending: false).limit(30);
    return (data as List).map((e) => TaskRequestEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancelTaskRequest(String id) async {
    await _client
        .from(SupabaseConfig.taskRequestsTable)
        .update({'status': 'CANCELADA', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  Future<void> completeTaskRequest(String id) async {
    await _client
        .from(SupabaseConfig.taskRequestsTable)
        .update({'status': 'COMPLETADA', 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id);
  }

  // ── Postulaciones (applications) ──────────────────────────────────────────
  Future<void> applyToTaskRequest(String taskRequestId, String yoerId, {String? proposal, double? proposedPrice}) async {
    await _client.from(SupabaseConfig.taskApplicationsTable).insert({
      'target_type': 'TASK_REQUEST',
      'task_request_id': taskRequestId,
      'yoer_id': yoerId,
      if (proposal != null) 'proposal': proposal,
      if (proposedPrice != null) 'proposed_price': proposedPrice,
    });
  }

  Future<void> applyToUrgentTask(String urgentTaskId, String yoerId, {String? proposal, double? proposedPrice}) async {
    await _client.from(SupabaseConfig.taskApplicationsTable).insert({
      'target_type': 'URGENT_TASK',
      'urgent_task_id': urgentTaskId,
      'yoer_id': yoerId,
      if (proposal != null) 'proposal': proposal,
      if (proposedPrice != null) 'proposed_price': proposedPrice,
    });
  }

  Future<List<TaskApplicationEntity>> getApplicationsForTaskRequest(String taskRequestId) async {
    final data = await _client
        .from(SupabaseConfig.taskApplicationsTable)
        .select(_applicationSelectWithYoer)
        .eq('task_request_id', taskRequestId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => TaskApplicationEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TaskApplicationEntity>> getMyApplications(String yoerId) async {
    final data = await _client
        .from(SupabaseConfig.taskApplicationsTable)
        .select()
        .eq('yoer_id', yoerId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => TaskApplicationEntity.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Acepta la postulación y asigna al YOER de forma atómica en el servidor
  /// (ver función `accept_task_application` en supabase_migration_v2.sql).
  Future<void> acceptApplication(TaskApplicationEntity app) async {
    await _client.rpc('accept_task_application', params: {'app_id': app.id});
  }

  Future<void> rejectApplication(String applicationId) async {
    await _client
        .from(SupabaseConfig.taskApplicationsTable)
        .update({'status': 'RECHAZADA'})
        .eq('id', applicationId);
  }
}
