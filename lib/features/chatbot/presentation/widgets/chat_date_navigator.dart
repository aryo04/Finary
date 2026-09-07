import 'package:flutter/material.dart';
import 'package:cakeu/shared/widgets/date_navigator_bar.dart';

/// Backward-compatible adapter forwarding to DateNavigatorBar
class ChatDateNavigator extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickCustomDate;
  final VoidCallback onSelectToday;

  const ChatDateNavigator({
    super.key,
    required this.selectedDate,
    required this.isToday,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onPickCustomDate,
    required this.onSelectToday,
  });

  @override
  Widget build(BuildContext context) {
    return DateNavigatorBar(
      selectedDate: selectedDate,
      isNextDisabled: isToday,
      onPrevious: onPreviousDay,
      onNext: isToday ? null : onNextDay,
      onPickDate: onPickCustomDate,
      badgeText: isToday ? null : 'Hari Ini',
      isBadgeHighlighted: true,
      onTapBadge: onSelectToday,
    );
  }
}
