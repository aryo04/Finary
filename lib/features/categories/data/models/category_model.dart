import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';

class CategoryModel {
  final String id;
  final String? userId;
  final String name;
  final String type; // 'income' or 'expense'
  final String icon;
  final String color;
  final bool isDefault;
  final DateTime? createdAt;

  CategoryModel({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#0D9488',
    this.isDefault = false,
    this.createdAt,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';
  Color get colorValue => AppColors.fromHex(color, fallback: isExpense ? AppColors.expense : AppColors.income);

  IconData get iconData => iconFromName(icon, isExpense: isExpense);

  static IconData iconFromName(String iconName, {bool isExpense = true}) {
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'makan':
      case 'makanan':
      case 'food':
        return Icons.restaurant_rounded;
      case 'directions_car':
      case 'transport':
      case 'transportasi':
      case 'bensin':
        return Icons.directions_car_rounded;
      case 'shopping_bag':
      case 'shopping':
      case 'belanja':
        return Icons.shopping_bag_rounded;
      case 'receipt_long':
      case 'tagihan':
      case 'bill':
        return Icons.receipt_long_rounded;
      case 'sports_esports':
      case 'hiburan':
      case 'game':
        return Icons.sports_esports_rounded;
      case 'medical_services':
      case 'kesehatan':
      case 'health':
        return Icons.medical_services_rounded;
      case 'school':
      case 'pendidikan':
      case 'education':
        return Icons.school_rounded;
      case 'account_balance_wallet':
      case 'gaji':
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      case 'work':
      case 'freelance':
      case 'bisnis':
        return Icons.work_rounded;
      case 'trending_up':
      case 'investasi':
        return Icons.trending_up_rounded;
      case 'card_giftcard':
      case 'hadiah':
      case 'bonus':
        return Icons.card_giftcard_rounded;
      case 'swap_horiz':
      case 'transfer':
        return Icons.swap_horiz_rounded;
      default:
        return isExpense ? Icons.category_rounded : Icons.attach_money_rounded;
    }
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#0D9488',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      if (userId != null) 'user_id': userId,
      'is_default': isDefault,
    };
  }
}
