import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/wallets/data/models/wallet_model.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/core/services/vault_security_service.dart';

class TransactionRepository {
  SupabaseClient get _client => SupabaseService.client;

  static const _selectQuery =
      'id, user_id, type, amount, category_id, wallet_id, description, transaction_date, source, created_at, category:categories(id, name, type, color, icon, is_default), wallet:wallets(id, name, type, color, icon, is_default)';

  Future<List<TransactionModel>> getTransactions({
    String? walletId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    var query = _client
        .from('transactions')
        .select(_selectQuery)
        .eq('user_id', user.id);

    if (walletId != null && walletId.isNotEmpty) {
      query = query.eq('wallet_id', walletId);
    }
    if (startDate != null) {
      query = query.gte('transaction_date', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('transaction_date', endDate.toIso8601String());
    }

    var orderedQuery = query.order('transaction_date', ascending: false);
    if (limit != null) {
      orderedQuery = orderedQuery.limit(limit);
    }

    final response = await orderedQuery;

    final List<TransactionModel> txList = (response as List<dynamic>)
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();

    // Ambil mutasi pindah saldo (transfers) agar tampil lengkap di 1 riwayat
    try {
      var trfQuery = _client
          .from('wallet_transfers')
          .select('id, user_id, from_wallet_id, to_wallet_id, amount, description, transfer_date, created_at, from_wallet:wallets!from_wallet_id(id, name, type, color, icon), to_wallet:wallets!to_wallet_id(id, name, type, color, icon)')
          .eq('user_id', user.id);

      if (walletId != null && walletId.isNotEmpty) {
        trfQuery = trfQuery.or('from_wallet_id.eq.$walletId,to_wallet_id.eq.$walletId');
      }
      if (startDate != null) {
        trfQuery = trfQuery.gte('transfer_date', startDate.toIso8601String());
      }
      if (endDate != null) {
        trfQuery = trfQuery.lte('transfer_date', endDate.toIso8601String());
      }

      var orderedTrfQuery = trfQuery.order('transfer_date', ascending: false);
      if (limit != null) {
        orderedTrfQuery = orderedTrfQuery.limit(limit);
      }

      final trfResponse = await orderedTrfQuery;

      for (final j in (trfResponse as List)) {
        final fromW = j['from_wallet'] != null ? WalletModel.fromJson(j['from_wallet']) : null;
        final toW = j['to_wallet'] != null ? WalletModel.fromJson(j['to_wallet']) : null;
        final fromName = fromW?.name ?? 'Dompet Asal';
        final toName = toW?.name ?? 'Dompet Tujuan';

        txList.add(
          TransactionModel(
            id: j['id'] as String,
            userId: j['user_id'] as String,
            walletId: j['from_wallet_id'] as String?,
            type: 'transfer',
            amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
            description: j['description'] as String?,
            transactionDate: j['transfer_date'] != null
                ? DateTime.parse(j['transfer_date'] as String).toLocal()
                : DateTime.now(),
            source: 'transfer',
            createdAt: j['created_at'] != null
                ? DateTime.parse(j['created_at'] as String).toLocal()
                : null,
            category: CategoryModel(
              id: 'transfer',
              userId: user.id,
              name: '$fromName ➔ $toName',
              type: 'transfer',
              color: '#0D9488',
              icon: 'swap_horiz',
              isDefault: true,
            ),
            wallet: fromW,
          ),
        );
      }
    } catch (_) {}

    txList.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return txList;
  }

  Future<TransactionModel> addTransaction({
    required String type,
    required double amount,
    String? categoryId,
    String? walletId,
    String? description,
    required DateTime transactionDate,
    String source = 'manual',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final finalDesc = description != null && description.isNotEmpty
        ? VaultSecurityService().encryptDescription(description)
        : description;

    final response = await _client
        .from('transactions')
        .insert({
          'user_id': user.id,
          'type': type,
          'amount': amount,
          'category_id': categoryId,
          ...?walletId == null ? null : {'wallet_id': walletId},
          'description': finalDesc,
          'transaction_date': transactionDate.toUtc().toIso8601String(),
          'source': source,
        })
        .select(_selectQuery)
        .single();

    return TransactionModel.fromJson(response);
  }

  /// Batch insert beberapa transaksi sekaligus dalam 1 request jaringan
  Future<List<TransactionModel>> addTransactionsBatch(List<Map<String, dynamic>> items) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User belum login');
    if (items.isEmpty) return [];

    final payload = items.map((item) {
      final txDate = item['transaction_date'] is DateTime
          ? (item['transaction_date'] as DateTime).toUtc().toIso8601String()
          : (item['transaction_date'] as String? ?? DateTime.now().toUtc().toIso8601String());

      final rawDesc = item['description'] as String?;
      final finalDesc = rawDesc != null && rawDesc.isNotEmpty
          ? VaultSecurityService().encryptDescription(rawDesc)
          : rawDesc;

      return {
        'user_id': user.id,
        'type': item['type'] ?? 'expense',
        'amount': item['amount'],
        'category_id': item['category_id'],
        ...?item['wallet_id'] == null ? null : {'wallet_id': item['wallet_id']},
        'description': finalDesc,
        'transaction_date': txDate,
        'source': item['source'] ?? 'ai_chat',
      };
    }).toList();

    final response = await _client
        .from('transactions')
        .insert(payload)
        .select(_selectQuery);

    return (response as List<dynamic>)
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> updateTransaction({
    required String id,
    required String type,
    required double amount,
    String? categoryId,
    String? walletId,
    String? description,
    required DateTime transactionDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final finalDesc = description != null && description.isNotEmpty
        ? VaultSecurityService().encryptDescription(description)
        : description;

    final response = await _client
        .from('transactions')
        .update({
          'type': type,
          'amount': amount,
          'category_id': categoryId,
          ...?walletId == null ? null : {'wallet_id': walletId},
          'description': finalDesc,
          'transaction_date': transactionDate.toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', user.id)
        .select(_selectQuery)
        .single();

    return TransactionModel.fromJson(response);
  }

  Future<void> deleteTransaction(String transactionId, {String type = 'expense'}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    if (type == 'transfer') {
      await _client
          .from('wallet_transfers')
          .delete()
          .eq('id', transactionId)
          .eq('user_id', user.id);
      return;
    }

    await _client
        .from('transactions')
        .delete()
        .eq('id', transactionId)
        .eq('user_id', user.id);

    // Bersihkan relasi transaction_id di chat_messages jika transaksi ini dicatat dari chatbot
    try {
      await _client
          .from('chat_messages')
          .update({'transaction_id': null})
          .eq('transaction_id', transactionId)
          .eq('user_id', user.id);
    } catch (_) {}
  }
}
