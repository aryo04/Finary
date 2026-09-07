import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';

class TransactionsPaginationBar extends StatelessWidget {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int pageSize;
  final int startIndex;
  final int endIndex;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final ValueChanged<int> onPageSizeChanged;

  const TransactionsPaginationBar({
    super.key,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
    required this.startIndex,
    required this.endIndex,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Info range
          Text(
            '${startIndex + 1}-$endIndex dari $totalItems',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),

          // Controls
          Row(
            children: [
              // Page size selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        onPageSizeChanged(val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Prev button
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: currentPage > 0 ? onPreviousPage : null,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: AppColors.primary,
              ),

              // Page indicator
              Text(
                '${currentPage + 1}/$totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              // Next button
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: currentPage < totalPages - 1 ? onNextPage : null,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
