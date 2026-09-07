import 'package:flutter/material.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/core/utils/date_formatter.dart';

class DashboardBalanceCard extends StatelessWidget {
  final double balance;
  final bool isBalanceVisible;
  final VoidCallback onToggleVisibility;

  const DashboardBalanceCard({
    super.key,
    required this.balance,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYear = '${AppDateFormatter.formatDate(now).split(' ')[1]} ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarker.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Saldo Utama',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  isBalanceVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isBalanceVisible ? CurrencyFormatter.format(balance) : 'Rp ••••••••',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Periode: $monthYear',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.credit_card_rounded,
                color: Colors.white24,
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
