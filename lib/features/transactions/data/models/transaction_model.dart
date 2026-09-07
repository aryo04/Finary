import 'package:cakeu/core/services/encryption_service.dart';
import 'package:cakeu/core/services/vault_security_service.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/wallets/data/models/wallet_model.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String? categoryId;
  final String? walletId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String? description;
  final DateTime transactionDate;
  final String source; // 'manual' or 'ai_chat'
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CategoryModel? category; // Joined relation
  final WalletModel? wallet; // Joined relation

  TransactionModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.walletId,
    required this.type,
    required this.amount,
    this.description,
    required this.transactionDate,
    this.source = 'manual',
    this.createdAt,
    this.updatedAt,
    this.category,
    this.wallet,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  bool get isTransfer => type == 'transfer';
  bool get isEncrypted => EncryptionService.isEncrypted(description ?? '');

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final rawDescription = json['description'] as String?;
    final decryptedDesc = rawDescription != null
        ? VaultSecurityService().decryptDescription(rawDescription)
        : null;

    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      walletId: json['wallet_id'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      description: decryptedDesc,
      transactionDate: json['transaction_date'] != null
          ? DateTime.parse(json['transaction_date'] as String).toLocal()
          : DateTime.now(),
      source: json['source'] as String? ?? 'manual',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
      category: (json['category'] != null && json['category'] is Map<String, dynamic>)
          ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : (json['categories'] != null && json['categories'] is Map<String, dynamic>)
              ? CategoryModel.fromJson(json['categories'] as Map<String, dynamic>)
              : null,
      wallet: (json['wallet'] != null && json['wallet'] is Map<String, dynamic>)
          ? WalletModel.fromJson(json['wallet'] as Map<String, dynamic>)
          : (json['wallets'] != null && json['wallets'] is Map<String, dynamic>)
              ? WalletModel.fromJson(json['wallets'] as Map<String, dynamic>)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (walletId != null) 'wallet_id': walletId,
      'type': type,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      'source': source,
    };
  }
}
