import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';

class ReportsWeeklyBarChart extends StatelessWidget {
  final List<double> weeklyTotals;
  final bool isExpense;
  final Animation<double> animation;

  const ReportsWeeklyBarChart({
    super.key,
    required this.weeklyTotals,
    required this.isExpense,
    required this.animation,
  });

  String _formatCompactRupiah(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}jt';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}rb';
    }
    return val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final maxVal = weeklyTotals.isNotEmpty ? weeklyTotals.reduce(math.max) : 1.0;
    final effectiveMax = maxVal > 0 ? maxVal : 1.0;
    final activeColor = isExpense ? AppColors.expense : AppColors.income;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpense ? 'Tren Pengeluaran per Pekan' : 'Tren Pemasukan per Pekan',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Icon(Icons.bar_chart_rounded, size: 18, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 130,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(weeklyTotals.length, (index) {
                    final val = weeklyTotals[index];
                    final heightRatio = (val / effectiveMax).clamp(0.05, 1.0);
                    final isHighest = val > 0 && val == maxVal;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            _formatCompactRupiah(val),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: isHighest ? FontWeight.w800 : FontWeight.w600,
                              color: isHighest ? activeColor : AppColors.textTertiary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: (80 * heightRatio * animation.value).clamp(4.0, 80.0),
                          decoration: BoxDecoration(
                            color: isHighest ? activeColor : activeColor.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mgg ${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isHighest ? FontWeight.w800 : FontWeight.w600,
                            color: isHighest ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
