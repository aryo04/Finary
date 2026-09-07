import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';

class ReportsMetricsGrid extends StatelessWidget {
  final double activeTotal;
  final int totalTransactions;
  final String topCategory;
  final double topCategoryPercent;
  final bool isExpenseTab;
  final DateTime selectedMonth;

  const ReportsMetricsGrid({
    super.key,
    required this.activeTotal,
    required this.totalTransactions,
    required this.topCategory,
    required this.topCategoryPercent,
    required this.isExpenseTab,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final dailyAvg = activeTotal / daysInMonth;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metrik Utama',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Rata-rata Harian',
                  value: CurrencyFormatter.format(dailyAvg),
                  badge: '/ hari',
                  icon: Icons.schedule_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: isExpenseTab ? 'Pos Terbesar' : 'Sumber Utama',
                  value: topCategory,
                  badge: activeTotal > 0 ? '${topCategoryPercent.toStringAsFixed(0)}%' : null,
                  icon: Icons.pie_chart_outline_rounded,
                  color: isExpenseTab ? AppColors.expense : AppColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Transaksi',
                  value: '$totalTransactions Transaksi',
                  badge: 'catatan',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Durasi Periode',
                  value: '$daysInMonth Hari',
                  badge: 'kalender',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    String? badge,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
