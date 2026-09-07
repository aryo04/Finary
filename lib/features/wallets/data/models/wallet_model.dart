import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';

class WalletModel {
  final String id;
  final String userId;
  final String name;
  final String type; // 'cash', 'bank', 'ewallet', 'other'
  final double initialBalance;
  final double currentBalance;
  final String icon;
  final String color;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    this.icon = 'account_balance_wallet',
    this.color = '#0D9488',
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCash => type == 'cash';
  bool get isBank => type == 'bank';
  bool get isEWallet => type == 'ewallet';

  Color get colorValue => AppColors.fromHex(color, fallback: const Color(0xFF0D9488));

  IconData get iconData {
    switch (icon.toLowerCase()) {
      case 'payments':
      case 'cash':
      case 'money':
        return Icons.payments_rounded;
      case 'account_balance':
      case 'bank':
        return Icons.account_balance_rounded;
      case 'smartphone':
      case 'phone_android':
      case 'ewallet':
        return Icons.smartphone_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      default:
        return isCash
            ? Icons.payments_rounded
            : isBank
                ? Icons.account_balance_rounded
                : isEWallet
                    ? Icons.smartphone_rounded
                    : Icons.account_balance_wallet_rounded;
    }
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Dompet',
      type: json['type'] as String? ?? 'cash',
      initialBalance: (json['initial_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ??
          (json['initial_balance'] as num?)?.toDouble() ??
          0.0,
      icon: json['icon'] as String? ?? 'account_balance_wallet',
      color: json['color'] as String? ?? '#0D9488',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
    };
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? initialBalance,
    double? currentBalance,
    String? icon,
    String? color,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
