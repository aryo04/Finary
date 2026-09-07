import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/features/reports/data/models/category_breakdown_data.dart';

class ReportsDonutChart extends StatelessWidget {
  final double totalAmount;
  final List<CategoryBreakdownData> categories;
  final bool isExpense;
  final Animation<double> animation;

  const ReportsDonutChart({
    super.key,
    required this.totalAmount,
    required this.categories,
    required this.isExpense,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
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
                isExpense ? 'Distribusi Pengeluaran' : 'Distribusi Pemasukan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isExpense ? AppColors.expense : AppColors.income).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${categories.length} Kategori',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Animated Donut Painter dengan label persentase di dalam arc
          Center(
            child: SizedBox(
              width: 210,
              height: 210,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _AnimatedDonutChartPainter(
                      categories: categories,
                      totalAmount: totalAmount,
                      progress: animation.value,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isExpense ? 'Total Keluar' : 'Total Masuk',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            CurrencyFormatter.format(totalAmount * animation.value),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: isExpense ? AppColors.expense : AppColors.income,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category Legend Chips dengan Persentase Jelas
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: categories.map((cat) {
              final percentage = totalAmount > 0 ? (cat.total / totalAmount * 100) : 0.0;
              final percentStr = percentage.toStringAsFixed(1);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cat.color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$percentStr%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: cat.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDonutChartPainter extends CustomPainter {
  final List<CategoryBreakdownData> categories;
  final double totalAmount;
  final double progress;

  _AnimatedDonutChartPainter({
    required this.categories,
    required this.totalAmount,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 30.0;
    final arcRadius = radius - strokeWidth / 2;

    // 1. Background track ring
    final bgPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, arcRadius, bgPaint);

    if (totalAmount <= 0 || categories.isEmpty || progress <= 0) return;

    double startAngle = -math.pi / 2;
    final totalSweepAngle = 2 * math.pi * progress;

    for (final cat in categories) {
      final ratio = cat.total / totalAmount;
      final sweepAngle = ratio * totalSweepAngle;
      if (sweepAngle <= 0) continue;

      // Draw Arc Segment
      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      // Draw Percentage label inside slice if slice is >= 4% and animation is near complete (> 60%)
      if (ratio >= 0.04 && progress >= 0.6) {
        final midAngle = startAngle + sweepAngle / 2;
        final labelX = center.dx + arcRadius * math.cos(midAngle);
        final labelY = center.dy + arcRadius * math.sin(midAngle);

        final percentInt = (ratio * 100).round();
        final textSpan = TextSpan(
          text: '$percentInt%',
          style: TextStyle(
            color: Colors.white,
            fontSize: ratio < 0.08 ? 8.5 : 10,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(
                color: Colors.black38,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedDonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.totalAmount != totalAmount ||
        oldDelegate.categories != categories;
  }
}
