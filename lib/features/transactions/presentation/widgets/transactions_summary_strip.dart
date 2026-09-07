import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';

class TransactionsSummaryStrip extends StatelessWidget {
  final double income;
  final double expense;

  const TransactionsSummaryStrip({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (income > 0)
            Row(
              children: [
                const Icon(Icons.arrow_downward_rounded, size: 12, color: AppColors.income),
                const SizedBox(width: 4),
                Text(
                  '+${CurrencyFormatter.format(income)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.income,
                  ),
                ),
              ],
            )
          else
            const SizedBox(),
          if (expense > 0)
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.expense),
                const SizedBox(width: 4),
                Text(
                  '-${CurrencyFormatter.format(expense)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.expense,
                  ),
                ),
              ],
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }
}
