// lib/features/bookings/data/datasources/booking_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../../shared/dto/service_dto.dart';

enum BookingStatus {
  pendiente, confirmada, enProgreso, completada, cancelada, rechazada;

  String get name {
    const map = {
      'pendiente': 'PENDIENTE',
      'confirmada': 'CONFIRMADA',
      'enProgreso': 'EN_PROGRESO',
      'completada': 'COMPLETADA',
      'cancelada': 'CANCELADA',
      'rechazada': 'RECHAZADA',
    };
    return map[toString().split('.').last] ?? 'PENDIENTE';
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pendiente:   return 'Pendiente';
      case BookingStatus.confirmada:  return 'Confirmada';
      case BookingStatus.enProgreso:  return 'En progreso';
      case BookingStatus.completada:  return 'Completada';
      case BookingStatus.cancelada:   return 'Cancelada';
      case BookingStatus.rechazada:   return 'Rechazada';
    }
  }
}

enum PaymentStatus { pendiente, pagado, reembolsado, fallido }

class BookingEntity {
  final String id;
  final String serviceId;
  final String yoerId;
  final String clientId;
  final String serviceName;
  final BookingStatus status;
  final int scheduledDate;
  final String scheduledTime;
  final int duration;
  final double? latitude;
  final double? longitude;
  final String address;
  final String? notes;
  final double totalPrice;
  final String currency;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  // Joins
  final Map<String, dynamic>? yoerProfile;
  final Map<String, dynamic>? clientProfile;

  const BookingEntity({
    required this.id,
    required this.serviceId,
    required this.yoerId,
    required this.clientId,
    required this.serviceName,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.duration,
    this.latitude,
    this.longitude,
    required this.address,
    this.notes,
    required this.totalPrice,
    this.currency = 'MXN',
    required this.paymentStatus,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.yoerProfile,
    this.clientProfile,
  });

  DateTime get scheduledDateTime =>
      DateTime.fromMillisecondsSinceEpoch(scheduledDate);

  String get yoerName => yoerProfile?['full_name'] as String? ?? 'YOER';
  String? get yoerImageUrl => yoerProfile?['profile_image_url'] as String?;
  String get clientName => clientProfile?['full_name'] as String? ?? 'Cliente';
  String? get clientImageUrl => clientProfile?['profile_image_url'] as String?;

  factory BookingEntity.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'PENDIENTE';
    final status = BookingStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => BookingStatus.pendiente,
    );
    final payStatusStr = json['payment_status'] as String? ?? 'PENDIENTE';
    final payStatus = PaymentStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == payStatusStr,
      orElse: () => PaymentStatus.pendiente,
    );

    return BookingEntity(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      yoerId: json['yoer_id'] as String,
      clientId: json['client_id'] as String,
      serviceName: json['service_name'] as String? ?? '',
      status: status,
      scheduledDate: json['scheduled_date'] as int,
      scheduledTime: json['scheduled_time'] as String,
      duration: json['duration'] as int,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String?,
      totalPrice: (json['total_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      paymentStatus: payStatus,
      paymentMethod: json['payment_method'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      yoerProfile: json['yoer_profile'] as Map<String, dynamic>?,
      clientProfile: json['client_profile'] as Map<String, dynamic>?,
    );
  }
}

class BookingRemoteDataSource {
  final SupabaseClient _client;

  BookingRemoteDataSource(this._client);

  static const _selectWithProfiles = '''
    *,
    yoer_profile:profiles!bookings_yoer_id_fkey(full_name, profile_image_url),
    client_profile:profiles!bookings_client_id_fkey(full_name, profile_image_url)
  ''';

  Future<List<BookingEntity>> getBookingsByClient(String clientId) async {
    final data = await _client
        .from(SupabaseConfig.bookingsTable)
        .select(_selectWithProfiles)
        .eq('client_id', clientId)
        .order('scheduled_date', ascending: false);

    return (data as List).map(_fromRow).toList();
  }

  Future<List<BookingEntity>> getBookingsByYoer(String yoerId) async {
    final data = await _client
        .from(SupabaseConfig.bookingsTable)
        .select(_selectWithProfiles)
        .eq('yoer_id', yoerId)
        .order('scheduled_date', ascending: false);

    return (data as List).map(_fromRow).toList();
  }

  Future<BookingEntity> getBookingById(String id) async {
    final data = await _client
        .from(SupabaseConfig.bookingsTable)
        .select(_selectWithProfiles)
        .eq('id', id)
        .single();

    return _fromRow(data);
  }

  Future<BookingEntity> createBooking({
    required String serviceId,
    required String yoerId,
    required String clientId,
    required String serviceName,
    required int scheduledDate,
    required String scheduledTime,
    required int duration,
    required String address,
    required double totalPrice,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final payload = {
      'service_id': serviceId,
      'yoer_id': yoerId,
      'client_id': clientId,
      'service_name': serviceName,
      'status': 'PENDIENTE',
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'duration': duration,
      'address': address,
      'total_price': totalPrice,
      'currency': 'MXN',
      'payment_status': 'PENDIENTE',
      if (notes != null) 'notes': notes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final data = await _client
        .from(SupabaseConfig.bookingsTable)
        .insert(payload)
        .select(_selectWithProfiles)
        .single();

    return _fromRow(data);
  }

  Future<BookingEntity> updateStatus(String id, BookingStatus status) async {
    final updates = <String, dynamic>{
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (status == BookingStatus.completada) {
      updates['completed_at'] = DateTime.now().toIso8601String();
    }
    if (status == BookingStatus.cancelada) {
      updates['cancelled_at'] = DateTime.now().toIso8601String();
    }

    final data = await _client
        .from(SupabaseConfig.bookingsTable)
        .update(updates)
        .eq('id', id)
        .select(_selectWithProfiles)
        .single();

    return _fromRow(data);
  }

  Future<BookingEntity> cancelBooking(String id, String reason) async {
    final data = await _client
        .from(SupabaseConfig.bookingsTable)
        .update({
          'status': 'CANCELADA',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancellation_reason': reason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select(_selectWithProfiles)
        .single();

    return _fromRow(data);
  }

  // ── Realtime stream de reservas ───────────────────────────────────────────
  Stream<List<BookingEntity>> watchBookingsByUser(String userId) {
    return _client
        .from(SupabaseConfig.bookingsTable)
        .stream(primaryKey: ['id'])
        .order('scheduled_date', ascending: false)
        .map((rows) => rows
            .where((r) => r['yoer_id'] == userId || r['client_id'] == userId)
            .map(_fromRow)
            .toList());
  }

  BookingEntity _fromRow(dynamic row) =>
      BookingEntity.fromJson(row as Map<String, dynamic>);
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKING VIEWMODEL
// lib/features/bookings/presentation/viewmodels/booking_viewmodel.dart
// (incluido aquí por organización)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingState {
  final bool isLoading;
  final List<BookingEntity> allBookings;
  final List<BookingEntity> upcomingBookings;
  final List<BookingEntity> completedBookings;
  final List<BookingEntity> cancelledBookings;
  final BookingEntity? selectedBooking;
  final String? error;
  final String? successMessage;

  const BookingState({
    this.isLoading = false,
    this.allBookings = const [],
    this.upcomingBookings = const [],
    this.completedBookings = const [],
    this.cancelledBookings = const [],
    this.selectedBooking,
    this.error,
    this.successMessage,
  });

  BookingState copyWith({
    bool? isLoading,
    List<BookingEntity>? allBookings,
    List<BookingEntity>? upcomingBookings,
    List<BookingEntity>? completedBookings,
    List<BookingEntity>? cancelledBookings,
    BookingEntity? selectedBooking,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      allBookings: allBookings ?? this.allBookings,
      upcomingBookings: upcomingBookings ?? this.upcomingBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      selectedBooking: selectedBooking ?? this.selectedBooking,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class BookingViewModel extends StateNotifier<BookingState> {
  final BookingRemoteDataSource _ds;

  BookingViewModel(this._ds) : super(const BookingState());

  void _categorize(List<BookingEntity> all) {
    final upcoming = all.where((b) =>
        b.status == BookingStatus.pendiente ||
        b.status == BookingStatus.confirmada ||
        b.status == BookingStatus.enProgreso).toList();
    final completed = all.where((b) => b.status == BookingStatus.completada).toList();
    final cancelled = all.where((b) =>
        b.status == BookingStatus.cancelada ||
        b.status == BookingStatus.rechazada).toList();

    state = state.copyWith(
      allBookings: all,
      upcomingBookings: upcoming,
      completedBookings: completed,
      cancelledBookings: cancelled,
      isLoading: false,
    );
  }

  Future<void> loadBookingsForClient(String clientId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bookings = await _ds.getBookingsByClient(clientId);
      _categorize(bookings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadBookingsForYoer(String yoerId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final bookings = await _ds.getBookingsByYoer(yoerId);
      _categorize(bookings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createBooking({
    required String serviceId,
    required String yoerId,
    required String clientId,
    required String serviceName,
    required int scheduledDate,
    required String scheduledTime,
    required int duration,
    required String address,
    required double totalPrice,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final booking = await _ds.createBooking(
        serviceId: serviceId,
        yoerId: yoerId,
        clientId: clientId,
        serviceName: serviceName,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        duration: duration,
        address: address,
        totalPrice: totalPrice,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
      );
      state = state.copyWith(
        isLoading: false,
        allBookings: [booking, ...state.allBookings],
        upcomingBookings: [booking, ...state.upcomingBookings],
        successMessage: '¡Reserva creada! Esperando confirmación del YOER.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> confirmBooking(String id) async {
    return _changeStatus(id, BookingStatus.confirmada, 'Reserva confirmada');
  }

  Future<bool> startBooking(String id) async {
    return _changeStatus(id, BookingStatus.enProgreso, 'Servicio iniciado');
  }

  Future<bool> completeBooking(String id) async {
    return _changeStatus(id, BookingStatus.completada, '¡Servicio completado!');
  }

  Future<bool> cancelBooking(String id, String reason) async {
    try {
      final updated = await _ds.cancelBooking(id, reason);
      _replaceBooking(updated);
      state = state.copyWith(successMessage: 'Reserva cancelada');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> _changeStatus(String id, BookingStatus status, String msg) async {
    try {
      final updated = await _ds.updateStatus(id, status);
      _replaceBooking(updated);
      state = state.copyWith(successMessage: msg);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void _replaceBooking(BookingEntity updated) {
    final all = state.allBookings.map((b) => b.id == updated.id ? updated : b).toList();
    _categorize(all);
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

// Providers
final bookingDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  return BookingRemoteDataSource(Supabase.instance.client);
});

final bookingViewModelProvider =
    StateNotifierProvider<BookingViewModel, BookingState>((ref) {
  return BookingViewModel(ref.read(bookingDataSourceProvider));
});
