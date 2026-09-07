import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

class TransactionDetailSheet extends StatelessWidget {
  final TransactionModel tx;
  final TransactionProvider provider;

  const TransactionDetailSheet({
    super.key,
    required this.tx,
    required this.provider,
  });

  static Future<void> show(
    BuildContext context,
    TransactionModel tx,
    TransactionProvider provider,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailSheet(
        tx: tx,
        provider: provider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = tx.isExpense;
    final categoryName = tx.category?.name ?? (isExpense ? 'Pengeluaran' : 'Pemasukan');
    final formattedDate = AppDateFormatter.formatDateTime(tx.transactionDate);
    final themeColor = isExpense ? AppColors.expense : AppColors.income;
    final themeBg = isExpense ? AppColors.expenseLight : AppColors.incomeLight;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Header: Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detail Transaksi',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Main Amount & Type Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: themeBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpense ? 'PENGELUARAN' : 'PEMASUKAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: themeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  isExpense
                      ? '-${CurrencyFormatter.format(tx.amount)}'
                      : '+${CurrencyFormatter.format(tx.amount)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Keterangan Lengkap (Full Description, No Truncation)
          const Text(
            'Keterangan Lengkap',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SelectableText(
              (tx.description != null && tx.description!.trim().isNotEmpty)
                  ? tx.description!
                  : 'Tidak ada catatan tambahan.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Rincian Informasi (Kategori, Dompet, Waktu)
          _buildInfoRow(
            icon: Icons.category_rounded,
            label: 'Kategori',
            value: categoryName,
          ),
          if (tx.wallet != null) ...[
            const Divider(height: 16, color: AppColors.border),
            _buildInfoRow(
              icon: tx.wallet!.iconData,
              label: 'Sumber Dana',
              value: tx.wallet!.name,
            ),
          ],
          const Divider(height: 16, color: AppColors.border),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Waktu Transaksi',
            value: formattedDate,
          ),
          const SizedBox(height: 24),

          // 6. Action Buttons: Hapus
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Hapus Transaksi'),
                        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      Navigator.pop(context);
                      final walletProvider = context.read<WalletProvider>();
                      walletProvider.adjustWalletBalance(
                        walletId: tx.walletId,
                        amount: tx.amount,
                        type: tx.type,
                        isAddition: false,
                      );
                      await provider.deleteTransaction(tx.id);
                      if (context.mounted) {
                        walletProvider.fetchWallets(forceRefresh: true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaksi berhasil dihapus')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 18),
                  label: const Text(
                    'Hapus Transaksi',
                    style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.expenseLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
