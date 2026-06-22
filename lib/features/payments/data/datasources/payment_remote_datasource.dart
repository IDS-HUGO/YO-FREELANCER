// lib/features/payments/data/datasources/payment_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/config/supabase_config.dart';
import '../../../../shared/dto/service_dto.dart';

enum PaymentMethodType {
  efectivo, tarjetaCredito, tarjetaDebito,
  transferencia, oxxo, paypal, mercadoPago;

  String get name {
    const map = {
      'efectivo': 'EFECTIVO',
      'tarjetaCredito': 'TARJETA_CREDITO',
      'tarjetaDebito': 'TARJETA_DEBITO',
      'transferencia': 'TRANSFERENCIA',
      'oxxo': 'OXXO',
      'paypal': 'PAYPAL',
      'mercadoPago': 'MERCADO_PAGO',
    };
    return map[toString().split('.').last] ?? 'EFECTIVO';
  }

  String get displayName {
    switch (this) {
      case PaymentMethodType.efectivo:        return 'Efectivo';
      case PaymentMethodType.tarjetaCredito:  return 'Tarjeta de crédito';
      case PaymentMethodType.tarjetaDebito:   return 'Tarjeta de débito';
      case PaymentMethodType.transferencia:   return 'Transferencia';
      case PaymentMethodType.oxxo:            return 'Pago en OXXO';
      case PaymentMethodType.paypal:          return 'PayPal';
      case PaymentMethodType.mercadoPago:     return 'Mercado Pago';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethodType.efectivo:        return '💵';
      case PaymentMethodType.tarjetaCredito:  return '💳';
      case PaymentMethodType.tarjetaDebito:   return '💳';
      case PaymentMethodType.transferencia:   return '🏦';
      case PaymentMethodType.oxxo:            return '🏪';
      case PaymentMethodType.paypal:          return '🅿️';
      case PaymentMethodType.mercadoPago:     return '🛒';
    }
  }
}

class PaymentEntity {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethodType paymentMethod;
  final String transactionType;
  final String status;
  final String? transactionId;
  final String? description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? processedAt;
  final DateTime? refundedAt;

  const PaymentEntity({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.currency = 'MXN',
    required this.paymentMethod,
    this.transactionType = 'PAGO',
    required this.status,
    this.transactionId,
    this.description,
    this.metadata = const {},
    required this.createdAt,
    this.processedAt,
    this.refundedAt,
  });

  bool get isPaid => status == 'PAGADO';
  bool get isPending => status == 'PENDIENTE';

  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)} $currency';
  }

  factory PaymentEntity.fromJson(Map<String, dynamic> json) {
    final methodStr = json['payment_method'] as String? ?? 'EFECTIVO';
    final method = PaymentMethodType.values.firstWhere(
      (e) => e.name == methodStr,
      orElse: () => PaymentMethodType.efectivo,
    );
    return PaymentEntity(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      paymentMethod: method,
      transactionType: json['transaction_type'] as String? ?? 'PAGO',
      status: json['status'] as String,
      transactionId: json['transaction_id'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'] as String)
          : null,
    );
  }
}

class PaymentCardEntity {
  final String id;
  final String userId;
  final String cardNumber;     // últimos 4 dígitos
  final String cardHolderName;
  final int expiryMonth;
  final int expiryYear;
  final String cardType;       // VISA, MASTERCARD, AMEX
  final bool isDefault;
  final DateTime createdAt;

  const PaymentCardEntity({
    required this.id,
    required this.userId,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardType,
    this.isDefault = false,
    required this.createdAt,
  });

  String get maskedNumber => '**** **** **** $cardNumber';
  String get expiryLabel =>
      '${expiryMonth.toString().padLeft(2, '0')}/$expiryYear';

  factory PaymentCardEntity.fromJson(Map<String, dynamic> json) {
    return PaymentCardEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cardNumber: json['card_number'] as String,
      cardHolderName: json['card_holder_name'] as String,
      expiryMonth: json['expiry_month'] as int,
      expiryYear: json['expiry_year'] as int,
      cardType: json['card_type'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PaymentRemoteDataSource {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  PaymentRemoteDataSource(this._client);

  Future<PaymentEntity> createPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required PaymentMethodType paymentMethod,
    String currency = 'MXN',
    String? description,
  }) async {
    final isImmediate = paymentMethod != PaymentMethodType.efectivo;
    final payload = {
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod.name,
      'transaction_type': 'PAGO',
      'status': isImmediate ? 'PAGADO' : 'PENDIENTE',
      if (description != null) 'description': description,
      if (isImmediate)
        'processed_at': DateTime.now().toIso8601String(),
      'metadata': {'source': 'flutter_app'},
    };

    final data = await _client
        .from(SupabaseConfig.paymentsTable)
        .insert(payload)
        .select()
        .single();

    // Si el pago fue exitoso, actualiza el booking
    if (isImmediate) {
      await _client
          .from(SupabaseConfig.bookingsTable)
          .update({'payment_status': 'PAGADO', 'payment_method': paymentMethod.name})
          .eq('id', bookingId);
    }

    return PaymentEntity.fromJson(data);
  }

  Future<List<PaymentEntity>> getPaymentsByUser(String userId) async {
    final data = await _client
        .from(SupabaseConfig.paymentsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => PaymentEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Tarjetas ───────────────────────────────────────────────────────────────
  Future<List<PaymentCardEntity>> getCardsByUser(String userId) async {
    final data = await _client
        .from('payment_cards')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);

    return (data as List)
        .map((e) => PaymentCardEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentCardEntity> addCard({
    required String userId,
    required String cardNumber,
    required String cardHolderName,
    required int expiryMonth,
    required int expiryYear,
    required String cardType,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await _client
          .from('payment_cards')
          .update({'is_default': false})
          .eq('user_id', userId);
    }

    final data = await _client.from('payment_cards').insert({
      'user_id': userId,
      'card_number': cardNumber,
      'card_holder_name': cardHolderName,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'card_type': cardType,
      'is_default': isDefault,
    }).select().single();

    return PaymentCardEntity.fromJson(data);
  }

  Future<void> deleteCard(String cardId) async {
    await _client.from('payment_cards').delete().eq('id', cardId);
  }

  Future<void> setDefaultCard(String userId, String cardId) async {
    await _client
        .from('payment_cards')
        .update({'is_default': false})
        .eq('user_id', userId);
    await _client
        .from('payment_cards')
        .update({'is_default': true})
        .eq('id', cardId);
  }
}

// ── Payment ViewModel ─────────────────────────────────────────────────────────
class PaymentState {
  final bool isLoading;
  final List<PaymentEntity> payments;
  final List<PaymentCardEntity> cards;
  final PaymentEntity? lastPayment;
  final String? error;
  final String? successMessage;

  const PaymentState({
    this.isLoading = false,
    this.payments = const [],
    this.cards = const [],
    this.lastPayment,
    this.error,
    this.successMessage,
  });

  PaymentState copyWith({
    bool? isLoading,
    List<PaymentEntity>? payments,
    List<PaymentCardEntity>? cards,
    PaymentEntity? lastPayment,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      payments: payments ?? this.payments,
      cards: cards ?? this.cards,
      lastPayment: lastPayment ?? this.lastPayment,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class PaymentViewModel extends StateNotifier<PaymentState> {
  final PaymentRemoteDataSource _ds;

  PaymentViewModel(this._ds) : super(const PaymentState());

  Future<void> loadPayments(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final payments = await _ds.getPaymentsByUser(userId);
      state = state.copyWith(isLoading: false, payments: payments);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadCards(String userId) async {
    try {
      final cards = await _ds.getCardsByUser(userId);
      state = state.copyWith(cards: cards);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> processPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required PaymentMethodType paymentMethod,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final payment = await _ds.createPayment(
        bookingId: bookingId,
        userId: userId,
        amount: amount,
        paymentMethod: paymentMethod,
        description: description,
      );
      state = state.copyWith(
        isLoading: false,
        lastPayment: payment,
        payments: [payment, ...state.payments],
        successMessage: 'Pago procesado exitosamente ✓',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> addCard({
    required String userId,
    required String cardNumber,
    required String cardHolderName,
    required int expiryMonth,
    required int expiryYear,
    required String cardType,
    bool isDefault = false,
  }) async {
    try {
      final card = await _ds.addCard(
        userId: userId,
        cardNumber: cardNumber,
        cardHolderName: cardHolderName,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cardType: cardType,
        isDefault: isDefault,
      );
      await loadCards(userId);
      state = state.copyWith(successMessage: 'Tarjeta agregada');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> deleteCard(String cardId, String userId) async {
    try {
      await _ds.deleteCard(cardId);
      await loadCards(userId);
      state = state.copyWith(successMessage: 'Tarjeta eliminada');
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

// Providers
final paymentDataSourceProvider = Provider<PaymentRemoteDataSource>((ref) {
  return PaymentRemoteDataSource(Supabase.instance.client);
});

final paymentViewModelProvider =
    StateNotifierProvider<PaymentViewModel, PaymentState>((ref) {
  return PaymentViewModel(ref.read(paymentDataSourceProvider));
});
