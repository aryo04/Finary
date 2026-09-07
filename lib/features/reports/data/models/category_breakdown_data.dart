import 'package:flutter/material.dart';

class CategoryBreakdownData {
  final String name;
  double total;
  final Color color;
  final IconData icon;
  int count;

  CategoryBreakdownData({
    required this.name,
    required this.total,
    required this.color,
    required this.icon,
    required this.count,
  });
}
