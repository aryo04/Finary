import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/features/wallets/data/models/wallet_model.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';
import 'package:cakeu/features/wallets/presentation/widgets/transfer_history_sheet.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';

class WalletTransferSheet extends StatefulWidget {
  final WalletModel? initialFromWallet;

  const WalletTransferSheet({super.key, this.initialFromWallet});

  static Future<bool?> show(BuildContext context, {WalletModel? initialFromWallet}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletTransferSheet(initialFromWallet: initialFromWallet),
    );
  }

  @override
  State<WalletTransferSheet> createState() => _WalletTransferSheetState();
}

class _WalletTransferSheetState extends State<WalletTransferSheet> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String? _fromWalletId;
  String? _toWalletId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<WalletProvider>().wallets;
    if (wallets.isNotEmpty) {
      _fromWalletId = widget.initialFromWallet?.id ?? wallets.first.id;
      if (wallets.length > 1) {
        _toWalletId = wallets.firstWhere((w) => w.id != _fromWalletId).id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleTransfer() async {
    final rawAmount = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final amount = double.tryParse(rawAmount) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal transfer harus lebih dari Rp0')),
      );
      return;
    }

    if (_fromWalletId == null || _toWalletId == null || _fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih dompet asal dan tujuan yang berbeda')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();

    final success = await walletProvider.transferFunds(
      fromWalletId: _fromWalletId!,
      toWalletId: _toWalletId!,
      amount: amount,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      await txProvider.fetchTransactions(forceRefresh: true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil memindahkan ${CurrencyFormatter.formatRupiah(amount)}!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(walletProvider.error ?? 'Gagal memproses transfer'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pindah Saldo Antar Dompet',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tarik tunai, top-up, atau transfer antar rekening',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Dari Dompet (Source)
          const Text('Dari Dompet:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _fromWalletId,
                isExpanded: true,
                items: wallets.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Row(
                      children: [
                        Icon(w.iconData, color: w.colorValue, size: 20),
                        const SizedBox(width: 10),
                        Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          CurrencyFormatter.formatRupiah(w.currentBalance),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _fromWalletId = val;
                    if (_toWalletId == val) {
                      _toWalletId = wallets.firstWhere((w) => w.id != val).id;
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Ke Dompet (Destination)
          const Text('Ke Dompet:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _toWalletId,
                isExpanded: true,
                items: wallets.map((w) {
                  return DropdownMenuItem(
                    value: w.id,
                    child: Row(
                      children: [
                        Icon(w.iconData, color: w.colorValue, size: 20),
                        const SizedBox(width: 10),
                        Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                          CurrencyFormatter.formatRupiah(w.currentBalance),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _toWalletId = val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nominal Transfer
          const Text('Nominal Pindah Saldo (Rp):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              hintText: '0',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          // Catatan / Keterangan
          const Text('Catatan (Opsional):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: 'Misal: Tarik tunai ATM, Top up GoPay',
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          // Tombol Pindah Saldo
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _handleTransfer,
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded),
            label: Text(_isSubmitting ? 'Memproses...' : 'Konfirmasi Pindah Saldo'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                TransferHistorySheet.show(context);
              },
              icon: const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
              label: const Text(
                'Lihat Riwayat Pindah Saldo',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
