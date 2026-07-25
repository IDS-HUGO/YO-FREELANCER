// lib/features/wallet/data/datasources/wallet_remote_datasource.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/config/supabase_config.dart';

enum WalletTransactionType {
  deposito, retiro, pagoRecibido, reembolso, comision, bono;

  static WalletTransactionType fromRaw(String raw) {
    const map = {
      'DEPOSITO': deposito,
      'RETIRO': retiro,
      'PAGO_RECIBIDO': pagoRecibido,
      'REEMBOLSO': reembolso,
      'COMISION': comision,
      'BONO': bono,
    };
    return map[raw] ?? deposito;
  }

  String get displayName {
    switch (this) {
      case WalletTransactionType.deposito:     return 'Depósito';
      case WalletTransactionType.retiro:       return 'Retiro';
      case WalletTransactionType.pagoRecibido:  return 'Pago recibido';
      case WalletTransactionType.reembolso:    return 'Reembolso';
      case WalletTransactionType.comision:     return 'Comisión';
      case WalletTransactionType.bono:         return 'Bono';
    }
  }

  bool get isCredit => this != WalletTransactionType.retiro && this != WalletTransactionType.comision;

  String get icon {
    switch (this) {
      case WalletTransactionType.deposito:     return '⬇️';
      case WalletTransactionType.retiro:       return '⬆️';
      case WalletTransactionType.pagoRecibido:  return '💰';
      case WalletTransactionType.reembolso:    return '↩️';
      case WalletTransactionType.comision:     return '📉';
      case WalletTransactionType.bono:         return '🎁';
    }
  }
}

enum WalletTransactionStatus {
  pendiente, completada, rechazada;

  static WalletTransactionStatus fromRaw(String raw) {
    const map = {'PENDIENTE': pendiente, 'COMPLETADA': completada, 'RECHAZADA': rechazada};
    return map[raw] ?? pendiente;
  }

  String get displayName {
    switch (this) {
      case WalletTransactionStatus.pendiente:  return 'Pendiente';
      case WalletTransactionStatus.completada: return 'Completada';
      case WalletTransactionStatus.rechazada:  return 'Rechazada';
    }
  }
}

class WalletAccountEntity {
  final String userId;
  final double balance;
  final double pendingBalance;
  final DateTime updatedAt;

  const WalletAccountEntity({
    required this.userId,
    this.balance = 0.0,
    this.pendingBalance = 0.0,
    required this.updatedAt,
  });

  factory WalletAccountEntity.fromJson(Map<String, dynamic> json) {
    return WalletAccountEntity(
      userId: json['user_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      pendingBalance: (json['pending_balance'] as num?)?.toDouble() ?? 0.0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class WalletTransactionEntity {
  final String id;
  final String userId;
  final WalletTransactionType type;
  final double amount;
  final WalletTransactionStatus status;
  final String? bookingId;
  final String? description;
  final DateTime createdAt;
  final DateTime? processedAt;

  const WalletTransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    this.bookingId,
    this.description,
    required this.createdAt,
    this.processedAt,
  });

  factory WalletTransactionEntity.fromJson(Map<String, dynamic> json) {
    return WalletTransactionEntity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: WalletTransactionType.fromRaw(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: WalletTransactionStatus.fromRaw(json['status'] as String? ?? 'PENDIENTE'),
      bookingId: json['booking_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at'] as String) : null,
    );
  }
}

class WalletRemoteDataSource {
  final SupabaseClient _client;
  WalletRemoteDataSource(this._client);

  Future<WalletAccountEntity> getAccount(String userId) async {
    final data = await _client
        .from(SupabaseConfig.walletAccountsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) {
      return WalletAccountEntity(userId: userId, updatedAt: DateTime.now());
    }
    return WalletAccountEntity.fromJson(data);
  }

  Future<List<WalletTransactionEntity>> getTransactions(String userId) async {
    final data = await _client
        .from(SupabaseConfig.walletTransactionsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => WalletTransactionEntity.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> requestWithdrawal(String userId, double amount, {String? description}) async {
    await _client.from(SupabaseConfig.walletTransactionsTable).insert({
      'user_id': userId,
      'type': 'RETIRO',
      'amount': amount,
      'status': 'PENDIENTE',
      if (description != null) 'description': description,
    });
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────
class WalletState {
  final bool isLoading;
  final WalletAccountEntity? account;
  final List<WalletTransactionEntity> transactions;
  final String? error;
  final String? successMessage;

  const WalletState({
    this.isLoading = false,
    this.account,
    this.transactions = const [],
    this.error,
    this.successMessage,
  });

  List<WalletTransactionEntity> get pending =>
      transactions.where((t) => t.status == WalletTransactionStatus.pendiente).toList();

  WalletState copyWith({
    bool? isLoading,
    WalletAccountEntity? account,
    List<WalletTransactionEntity>? transactions,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      account: account ?? this.account,
      transactions: transactions ?? this.transactions,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class WalletViewModel extends StateNotifier<WalletState> {
  final WalletRemoteDataSource _ds;
  WalletViewModel(this._ds) : super(const WalletState());

  Future<void> load(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final account = await _ds.getAccount(userId);
      final transactions = await _ds.getTransactions(userId);
      state = state.copyWith(isLoading: false, account: account, transactions: transactions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> requestWithdrawal(String userId, double amount, {String? description}) async {
    if (state.account != null && amount > state.account!.balance) {
      state = state.copyWith(error: 'No tienes saldo suficiente para retirar esa cantidad.');
      return false;
    }
    try {
      await _ds.requestWithdrawal(userId, amount, description: description);
      await load(userId);
      state = state.copyWith(successMessage: 'Solicitud de retiro enviada, la procesaremos pronto.');
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(clearError: true, clearSuccess: true);
}

final walletDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(Supabase.instance.client);
});

final walletViewModelProvider = StateNotifierProvider<WalletViewModel, WalletState>((ref) {
  return WalletViewModel(ref.read(walletDataSourceProvider));
});
