import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';

class TransactionsSegmentedFilter extends StatelessWidget {
  final String selectedFilter;
  final List<TransactionModel> allList;
  final bool filterByDate;
  final DateTime selectedDate;
  final ValueChanged<String> onFilterChanged;

  const TransactionsSegmentedFilter({
    super.key,
    required this.selectedFilter,
    required this.allList,
    required this.filterByDate,
    required this.selectedDate,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final targetList = filterByDate
        ? allList.where((t) => _isSameDay(t.transactionDate, selectedDate)).toList()
        : allList;

    final expenseCount = targetList.where((t) => t.isExpense).length;
    final incomeCount = targetList.where((t) => t.isIncome).length;
    final transferCount = targetList.where((t) => t.isTransfer).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildSegmentItem(
              title: 'Semua',
              count: targetList.length,
              value: 'all',
              activeColor: AppColors.primary,
            ),
            _buildSegmentItem(
              title: 'Pengeluaran',
              count: expenseCount,
              value: 'expense',
              activeColor: AppColors.expense,
            ),
            _buildSegmentItem(
              title: 'Pemasukan',
              count: incomeCount,
              value: 'income',
              activeColor: AppColors.income,
            ),
            _buildSegmentItem(
              title: 'Transfer',
              count: transferCount,
              value: 'transfer',
              activeColor: const Color(0xFF0F766E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentItem({
    required String title,
    required int count,
    required String value,
    required Color activeColor,
  }) {
    final isSelected = selectedFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => onFilterChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.12)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? activeColor : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
