import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/date_formatter.dart';

/// Reusable Date Navigation Bar for Transactions, Chatbot, and Reports.
class DateNavigatorBar extends StatelessWidget {
  final DateTime selectedDate;
  final bool isNextDisabled;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onPickDate;
  final String? customTitle;
  final String? badgeText;
  final bool isBadgeHighlighted;
  final VoidCallback? onTapBadge;
  final EdgeInsetsGeometry margin;

  const DateNavigatorBar({
    super.key,
    required this.selectedDate,
    this.isNextDisabled = false,
    this.onPrevious,
    this.onNext,
    this.onPickDate,
    this.customTitle,
    this.badgeText,
    this.isBadgeHighlighted = false,
    this.onTapBadge,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 4),
  });

  @override
  Widget build(BuildContext context) {
    final title = customTitle ?? AppDateFormatter.formatDayTitle(selectedDate);

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.textPrimary),
            onPressed: onPrevious,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Expanded(
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: isNextDisabled ? AppColors.textTertiary : AppColors.textPrimary,
                ),
                onPressed: isNextDisabled ? null : onNext,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onTapBadge,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBadgeHighlighted ? AppColors.primaryContainer : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isBadgeHighlighted ? AppColors.primaryDarker : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
