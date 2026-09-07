import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/transactions/presentation/widgets/transaction_detail_sheet.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

class TransactionItemTile extends StatelessWidget {
  final TransactionModel tx;
  final TransactionProvider provider;
  final bool enableDismissible;

  const TransactionItemTile({
    super.key,
    required this.tx,
    required this.provider,
    this.enableDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _buildTile(context);
    if (!enableDismissible) {
      return tile;
    }

    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Hapus Transaksi'),
            content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteTransaction(tx.id);
        context.read<WalletProvider>().adjustWalletBalance(
          walletId: tx.walletId,
          amount: tx.amount,
          type: tx.type,
          isAddition: false,
        );
        context.read<WalletProvider>().fetchWallets(forceRefresh: true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi berhasil dihapus')),
        );
      },
      child: tile,
    );
  }

  Widget _buildTile(BuildContext context) {
    final isExpense = tx.isExpense;
    final dateStr = AppDateFormatter.formatDateTime(tx.transactionDate);
    final categoryName = tx.category?.name ?? (isExpense ? 'Pengeluaran' : 'Pemasukan');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => TransactionDetailSheet.show(context, tx, provider),
        borderRadius: BorderRadius.circular(16),
        child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tx.isTransfer
                        ? const Color(0xFFCCFBF1)
                        : (isExpense ? AppColors.expenseLight : AppColors.incomeLight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tx.isTransfer
                        ? Icons.swap_horiz_rounded
                        : (isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                    color: tx.isTransfer
                        ? const Color(0xFF0F766E)
                        : (isExpense ? AppColors.expense : AppColors.income),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (tx.wallet != null && !tx.isTransfer)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: tx.wallet!.colorValue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(tx.wallet!.iconData, size: 10, color: tx.wallet!.colorValue),
                                  const SizedBox(width: 3),
                                  Text(
                                    tx.wallet!.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: tx.wallet!.colorValue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (tx.description != null && tx.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tx.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tx.isTransfer
                      ? CurrencyFormatter.format(tx.amount)
                      : (isExpense
                          ? '-${CurrencyFormatter.format(tx.amount)}'
                          : '+${CurrencyFormatter.format(tx.amount)}'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: tx.isTransfer
                        ? const Color(0xFF0F766E)
                        : (isExpense ? AppColors.expense : AppColors.income),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
