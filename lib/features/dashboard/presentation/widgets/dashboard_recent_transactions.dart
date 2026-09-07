import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/transactions/presentation/widgets/transaction_item_tile.dart';

class DashboardRecentTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;
  final bool isLoading;

  const DashboardRecentTransactions({
    super.key,
    required this.transactions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/transactions'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Content
        if (isLoading && transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (transactions.isEmpty)
          _buildEmptyState(context)
        else
          ...transactions.map((tx) => TransactionItemTile(
                tx: tx,
                provider: context.read<TransactionProvider>(),
                enableDismissible: false,
              )),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.textTertiary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Transaksi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Catat transaksi pengeluaran atau pemasukan pertamamu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/transactions/add'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Catat Sekarang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
