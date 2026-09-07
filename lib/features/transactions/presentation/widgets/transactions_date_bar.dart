import 'package:flutter/material.dart';
import 'package:cakeu/shared/widgets/date_navigator_bar.dart';

/// Backward-compatible adapter forwarding to DateNavigatorBar
class TransactionsDateBar extends StatelessWidget {
  final DateTime selectedDate;
  final bool filterByDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickCustomDate;
  final VoidCallback onToggleFilterByDate;

  const TransactionsDateBar({
    super.key,
    required this.selectedDate,
    required this.filterByDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickCustomDate,
    required this.onToggleFilterByDate,
  });

  @override
  Widget build(BuildContext context) {
    return DateNavigatorBar(
      selectedDate: selectedDate,
      onPrevious: filterByDate ? onPreviousDay : null,
      onNext: filterByDate ? onNextDay : null,
      onPickDate: onPickCustomDate,
      customTitle: filterByDate ? null : 'Semua Tanggal',
      badgeText: filterByDate ? 'Semua' : 'Hari Ini',
      isBadgeHighlighted: !filterByDate,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      onTapBadge: onToggleFilterByDate,
    );
  }
}
