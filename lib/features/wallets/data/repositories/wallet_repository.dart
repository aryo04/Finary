import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/features/wallets/data/models/wallet_model.dart';
import 'package:cakeu/features/wallets/data/models/wallet_transfer_model.dart';

class WalletRepository {
  final SupabaseClient _client;

  WalletRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Mengambil seluruh dompet milik pengguna lengkap dengan saldo terkini yang presisi
  Future<List<WalletModel>> getWallets() async {
    final userId = currentUserId;
    if (userId == null) return [];

    // 1. Coba panggil RPC get_financial_summary terlebih dahulu
    try {
      final summary = await _client.rpc('get_financial_summary');
      if (summary != null && summary['wallets'] != null && summary['wallets'] is List) {
        final List<dynamic> rawList = summary['wallets'];
        final list = rawList.map((j) => WalletModel.fromJson(j as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {}

    // 2. Fallback: Query tabel wallets dan hitung saldo terkini dari tabel transactions
    final walletsResponse = await _client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false)
        .order('created_at', ascending: true);

    final rawWallets = (walletsResponse as List)
        .map((j) => WalletModel.fromJson(j as Map<String, dynamic>))
        .toList();

    if (rawWallets.isEmpty) return [];

    final defaultWalletId = rawWallets.where((w) => w.isDefault).firstOrNull?.id ?? rawWallets.first.id;

    // Ambil transaksi dan transfer untuk menghitung saldo per dompet
    try {
      final txResponse = await _client
          .from('transactions')
          .select('wallet_id, type, amount')
          .eq('user_id', userId);

      final transferResponse = await _client
          .from('wallet_transfers')
          .select('from_wallet_id, to_wallet_id, amount')
          .eq('user_id', userId);

      final Map<String, double> incomeMap = {};
      final Map<String, double> expenseMap = {};
      final Map<String, double> transferInMap = {};
      final Map<String, double> transferOutMap = {};

      for (final tx in (txResponse as List)) {
        final wId = (tx['wallet_id'] as String?) ?? defaultWalletId;
        final type = tx['type'] as String? ?? 'expense';
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

        if (type == 'income') {
          incomeMap[wId] = (incomeMap[wId] ?? 0.0) + amount;
        } else {
          expenseMap[wId] = (expenseMap[wId] ?? 0.0) + amount;
        }
      }

      for (final trf in (transferResponse as List)) {
        final fromId = trf['from_wallet_id'] as String;
        final toId = trf['to_wallet_id'] as String;
        final amount = (trf['amount'] as num?)?.toDouble() ?? 0.0;

        transferOutMap[fromId] = (transferOutMap[fromId] ?? 0.0) + amount;
        transferInMap[toId] = (transferInMap[toId] ?? 0.0) + amount;
      }

      return rawWallets.map((w) {
        final inc = incomeMap[w.id] ?? 0.0;
        final exp = expenseMap[w.id] ?? 0.0;
        final trfIn = transferInMap[w.id] ?? 0.0;
        final trfOut = transferOutMap[w.id] ?? 0.0;
        final currBal = w.initialBalance + inc - exp + trfIn - trfOut;
        return w.copyWith(currentBalance: currBal);
      }).toList();
    } catch (_) {
      return rawWallets;
    }
  }

  /// Membuat dompet baru
  Future<WalletModel> createWallet({
    required String name,
    required String type,
    double initialBalance = 0.0,
    String icon = 'account_balance_wallet',
    String color = '#0D9488',
    bool isDefault = false,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Pengguna belum masuk');

    final response = await _client
        .from('wallets')
        .insert({
          'user_id': userId,
          'name': name,
          'type': type,
          'initial_balance': initialBalance,
          'icon': icon,
          'color': color,
          'is_default': isDefault,
        })
        .select()
        .single();

    return WalletModel.fromJson(response);
  }

  /// Memperbarui informasi dompet
  Future<WalletModel> updateWallet({
    required String id,
    String? name,
    String? type,
    double? initialBalance,
    String? icon,
    String? color,
    bool? isDefault,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Pengguna belum masuk');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (initialBalance != null) updates['initial_balance'] = initialBalance;
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (isDefault != null) updates['is_default'] = isDefault;

    final response = await _client
        .from('wallets')
        .update(updates)
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

    return WalletModel.fromJson(response);
  }

  /// Menghapus dompet
  Future<void> deleteWallet(String id) async {
    final userId = currentUserId;
    if (userId == null) return;
    await _client
        .from('wallets')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Pindah saldo (Transfer Antar Dompet)
  Future<Map<String, dynamic>> transferFunds({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    final response = await _client.rpc('transfer_wallet_funds', params: {
      'p_from_wallet_id': fromWalletId,
      'p_to_wallet_id': toWalletId,
      'p_amount': amount,
      'p_description': description,
      'p_date': (date ?? DateTime.now()).toIso8601String(),
    });

    return response as Map<String, dynamic>;
  }

  /// Mengambil riwayat pemindahan saldo (transfers)
  Future<List<WalletTransferModel>> getTransfers() async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('wallet_transfers')
          .select('id, user_id, from_wallet_id, to_wallet_id, amount, description, transfer_date, created_at, from_wallet:wallets!from_wallet_id(name), to_wallet:wallets!to_wallet_id(name)')
          .eq('user_id', userId)
          .order('transfer_date', ascending: false);

      return (response as List)
          .map((j) => WalletTransferModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Menghapus catatan pindah saldo (membatalkan transfer)
  Future<void> deleteTransfer(String transferId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client
        .from('wallet_transfers')
        .delete()
        .eq('id', transferId)
        .eq('user_id', userId);
  }
}
