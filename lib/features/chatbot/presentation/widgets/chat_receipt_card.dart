import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/features/categories/presentation/providers/category_provider.dart';
import 'package:cakeu/features/chatbot/data/models/chat_message_model.dart';
import 'package:cakeu/features/chatbot/presentation/providers/chatbot_provider.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

class ChatReceiptCard extends StatefulWidget {
  final ChatMessageModel message;
  final ExtractedTransaction extracted;

  const ChatReceiptCard({
    super.key,
    required this.message,
    required this.extracted,
  });

  @override
  State<ChatReceiptCard> createState() => _ChatReceiptCardState();
}

class _ChatReceiptCardState extends State<ChatReceiptCard> {
  String? _selectedWalletId;
  final Map<int, String> _groupWalletIds = {};
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.extracted.transactionDate ?? widget.message.createdAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSelectedWallet();
    });
  }

  void _initSelectedWallet() {
    final wallets = context.read<WalletProvider>().wallets;
    if (wallets.isEmpty) return;

    // Inisialisasi wallet untuk setiap group (Multi-Kategori / Split Payment)
    final groups = widget.extracted.groups;
    if (groups != null && groups.length > 1) {
      for (int i = 0; i < groups.length; i++) {
        final grp = groups[i];
        String? resolvedId;
        if (grp.walletId != null) {
          resolvedId = wallets.where((w) => w.id == grp.walletId).firstOrNull?.id;
        }
        if (resolvedId == null && grp.walletName != null && grp.walletName!.isNotEmpty) {
          final target = grp.walletName!.toLowerCase();
          resolvedId = wallets.where((w) => w.name.toLowerCase().contains(target) || target.contains(w.name.toLowerCase())).firstOrNull?.id;
          if (resolvedId == null) {
            if (target.contains('tunai') || target.contains('cash')) {
              resolvedId = wallets.where((w) => w.isCash).firstOrNull?.id;
            } else if (target.contains('bank') || target.contains('rekening')) {
              resolvedId = wallets.where((w) => w.isBank).firstOrNull?.id;
            } else if (target.contains('ewallet') || target.contains('e-wallet') || target.contains('qris') || target.contains('gopay') || target.contains('ovo') || target.contains('dana')) {
              resolvedId = wallets.where((w) => w.isEWallet).firstOrNull?.id ?? wallets.where((w) => w.isBank).firstOrNull?.id;
            }
          }
        }
        if (resolvedId == null) {
          final grpText = '${grp.description} ${grp.items.map((it) => it.name).join(' ')}'.toLowerCase();
          if (grpText.contains('cash') || grpText.contains('tunai')) {
            resolvedId = wallets.where((w) => w.isCash).firstOrNull?.id;
          } else if (grpText.contains('qris') || grpText.contains('gopay') || grpText.contains('ovo') || grpText.contains('dana')) {
            resolvedId = wallets.where((w) => w.isEWallet).firstOrNull?.id ?? wallets.where((w) => w.isBank).firstOrNull?.id;
          } else if (grpText.contains('rek') || grpText.contains('bank') || grpText.contains('transfer')) {
            resolvedId = wallets.where((w) => w.isBank).firstOrNull?.id;
          }
        }
        _groupWalletIds[i] = resolvedId ?? context.read<WalletProvider>().defaultWallet?.id ?? wallets.first.id;
      }
    }

    // 1. Cek jika AI sudah memberikan walletId yang cocok
    if (widget.extracted.walletId != null) {
      final match = wallets.where((w) => w.id == widget.extracted.walletId).firstOrNull;
      if (match != null) {
        setState(() => _selectedWalletId = match.id);
        return;
      }
    }

    // 2. Cek jika ada walletName dari AI yang cocok dengan nama dompet user
    if (widget.extracted.walletName != null && widget.extracted.walletName!.isNotEmpty) {
      final wName = widget.extracted.walletName!.toLowerCase();
      final match = wallets.where((w) =>
          w.name.toLowerCase().contains(wName) ||
          wName.contains(w.name.toLowerCase())).firstOrNull;
      if (match != null) {
        setState(() => _selectedWalletId = match.id);
        return;
      }
    }

    // 3. Gabungkan seluruh konteks teks (paymentMethod, deskripsi, isi pesan user)
    final textContext = '${widget.extracted.paymentMethod ?? ''} ${widget.extracted.description ?? ''} ${widget.message.content}'.toLowerCase();

    // 3a. Cek kecocokan langsung dengan nama dompet/rekening pengguna (misal user punya dompet bernama "BCA", "GoPay", "Dompet Utama")
    for (final w in wallets) {
      final cleanWName = w.name.toLowerCase().trim();
      if (cleanWName.isNotEmpty && cleanWName.length > 2 && textContext.contains(cleanWName)) {
        setState(() => _selectedWalletId = w.id);
        return;
      }
    }

    // 3b. Deteksi kata kunci Rekening / Bank / QRIS
    final bankKeywords = [
      'rek', 'rekening', 'bank', 'transfer', 'tf', 'm-banking', 'mbanking',
      'atm', 'debit', 'bca', 'mandiri', 'bri', 'bni', 'jago', 'seabank',
      'cimb', 'permata', 'bsi', 'qris', 'scan qris', 'masuk rek', 'ke rek'
    ];
    final hasBankKeyword = bankKeywords.any((k) {
      final regex = RegExp(r'(^|\s|[^\w])' + RegExp.escape(k) + r'($|\s|[^\w])');
      return regex.hasMatch(textContext);
    });
    if (hasBankKeyword) {
      final bank = wallets.where((w) => w.isBank).firstOrNull;
      if (bank != null) {
        setState(() => _selectedWalletId = bank.id);
        return;
      }
    }

    // 3c. Deteksi kata kunci Tunai / Cash
    final cashKeywords = [
      'tunai', 'cash', 'uang tunai', 'uang fisik', 'uang pas', 'uang saku',
      'kembalian', 'dompet tunai', 'uang meja', 'secara tunai', 'pake cash', 'make tunai'
    ];
    final hasCashKeyword = cashKeywords.any((k) {
      final regex = RegExp(r'(^|\s|[^\w])' + RegExp.escape(k) + r'($|\s|[^\w])');
      return regex.hasMatch(textContext);
    });
    if (hasCashKeyword) {
      final cash = wallets.where((w) => w.isCash).firstOrNull;
      if (cash != null) {
        setState(() => _selectedWalletId = cash.id);
        return;
      }
    }

    // 3d. Deteksi kata kunci E-Wallet
    final ewalletKeywords = [
      'gopay', 'ovo', 'dana', 'shopeepay', 'spay', 'linkaja', 'ewallet',
      'e-wallet', 'isaku', 'sakuku', 'dompet digital'
    ];
    final hasEWalletKeyword = ewalletKeywords.any((k) => textContext.contains(k));
    if (hasEWalletKeyword) {
      final ewallet = wallets.where((w) => w.isEWallet).firstOrNull;
      if (ewallet != null) {
        setState(() => _selectedWalletId = ewallet.id);
        return;
      }
    }

    // 4. Default wallet
    final defaultW = context.read<WalletProvider>().defaultWallet;
    setState(() => _selectedWalletId = defaultW?.id ?? wallets.first.id);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatbotProvider>();
    final catProvider = context.read<CategoryProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;

    final extracted = widget.extracted;
    final message = widget.message;

    final isExpense = extracted.isExpense;
    final isReceipt = extracted.isReceipt || (extracted.items != null && (extracted.tax != null || extracted.subtotal != null));
    final isNonCash = extracted.paymentMethod != null &&
        !extracted.paymentMethod!.toLowerCase().contains('tunai') &&
        !extracted.paymentMethod!.toLowerCase().contains('cash');
    final txProvider = context.watch<TransactionProvider>();
    final txId = message.transactionId;
    final isActuallySaved = message.isSaved &&
        (txId == null ||
            txId.isEmpty ||
            !txProvider.hasLoadedOnce ||
            txProvider.transactions.any((t) => t.id == txId));
    final wasDeletedFromHistory = message.isSaved && !isActuallySaved;
    final isSaved = isActuallySaved;

    final amount = extracted.amount ?? 0;
    final hasItems = extracted.items != null && extracted.items!.isNotEmpty;
    final txDate = (_selectedDateTime ?? extracted.transactionDate ?? message.createdAt).toLocal();
    final dateTimeNow =
        '${AppDateFormatter.formatDate(txDate)}, ${txDate.hour.toString().padLeft(2, '0')}:${txDate.minute.toString().padLeft(2, '0')}';

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.85,
      ),
      margin: const EdgeInsets.only(bottom: 12, top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSaved
              ? AppColors.income
              : (wasDeletedFromHistory ? AppColors.warning : AppColors.primary),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isExpense ? AppColors.expense : AppColors.income).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isReceipt
                          ? Icons.receipt_long_rounded
                          : (isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                      size: 13,
                      color: isExpense ? AppColors.expense : AppColors.income,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isReceipt ? 'Struk Kasir' : (isExpense ? 'Pengeluaran' : 'Pemasukan'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isExpense ? AppColors.expense : AppColors.income,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isSaved)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.income, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Tersimpan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.income,
                      ),
                    ),
                  ],
                )
              else if (wasDeletedFromHistory)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.warning, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Dihapus • Simpan Ulang',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isExpense ? AppColors.expense : AppColors.income,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Multi-Kategori / Split Payment Groups Card
          if (!isReceipt && extracted.groups != null && extracted.groups!.length > 1) ...[
            ...extracted.groups!.asMap().entries.map((entry) {
              final idx = entry.key;
              final grp = entry.value;
              final currentWalletId = _groupWalletIds[idx] ?? _selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null);
              final currentWallet = wallets.where((w) => w.id == currentWalletId).firstOrNull ?? (wallets.isNotEmpty ? wallets.first : null);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.folder_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              grp.categoryName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          CurrencyFormatter.format(grp.totalAmount),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: grp.isExpense ? AppColors.expense : AppColors.income,
                          ),
                        ),
                      ],
                    ),
                    if (grp.items.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...grp.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.qty > 1
                                      ? '• ${item.name} (${item.qty}x)'
                                      : '• ${item.name}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.price != null)
                                Text(
                                  CurrencyFormatter.format(item.price!),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (wallets.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, size: 13, color: AppColors.primary),
                            const SizedBox(width: 6),
                            const Text('Dompet: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            if (isSaved) ...[
                              Text(
                                currentWallet?.name ?? 'Dompet',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                            ] else ...[
                              Expanded(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: currentWalletId ?? wallets.first.id,
                                    isDense: true,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    items: wallets.map((w) {
                                      return DropdownMenuItem<String>(
                                        value: w.id,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(w.iconData, size: 12, color: w.colorValue),
                                            const SizedBox(width: 4),
                                            Text(w.name),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _groupWalletIds[idx] = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else ...[
            // Single Card Item Breakdown
            if (hasItems) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rincian Item:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${extracted.items!.length} item',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...extracted.items!.map(
                      (item) {
                        final priceStr = item.price != null
                            ? CurrencyFormatter.format(item.price!)
                            : '-';
                        final qtyStr = item.qty > 1
                            ? ' (${item.qty}x)'
                            : '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '• ${item.name}$qtyStr',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                priceStr,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    if (isReceipt) ...[
                      if (extracted.subtotal != null &&
                          extracted.subtotal! > 0 &&
                          extracted.subtotal != amount) ...[
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Text(CurrencyFormatter.format(extracted.subtotal!),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                      if (extracted.discount != null && extracted.discount! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diskon / Promo:',
                                  style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600)),
                              Text('-${CurrencyFormatter.format(extracted.discount!)}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      if (extracted.tax != null && extracted.tax! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pajak (PPN/PB1):',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text('+${CurrencyFormatter.format(extracted.tax!)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                      const Divider(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Biaya:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(amount),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isExpense ? AppColors.expense : AppColors.income,
                            ),
                          ),
                        ],
                      ),

                      if (extracted.paidAmount != null && extracted.paidAmount! > 0) ...[
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              extracted.paymentMethod != null && extracted.paymentMethod!.isNotEmpty
                                  ? 'Bayar (${extracted.paymentMethod}):'
                                  : 'Bayar Tunai:',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(CurrencyFormatter.format(extracted.paidAmount!),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (!isNonCash && extracted.changeAmount != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Kembalian:',
                                  style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600)),
                              Text(CurrencyFormatter.format(extracted.changeAmount!),
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ],
                      ] else if (extracted.paymentMethod != null && extracted.paymentMethod!.isNotEmpty) ...[
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Metode Pembayaran:',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                extracted.paymentMethod!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDarker,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('Kategori: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    extracted.categoryName ?? 'Lainnya',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),

          // Pilihan Dompet / Rekening (Sumber Dana) - Hanya tampil jika BUKAN multi-grup split payment
          if (wallets.isNotEmpty && (extracted.groups == null || extracted.groups!.length <= 1)) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  const Text('Dompet: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  if (isSaved) ...[
                    Text(
                      wallets.where((w) => w.id == _selectedWalletId).firstOrNull?.name ?? 'Dompet Utama',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ] else ...[
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedWalletId ?? wallets.first.id,
                          isDense: true,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          items: wallets.map((w) {
                            return DropdownMenuItem<String>(
                              value: w.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(w.iconData, size: 13, color: w.colorValue),
                                  const SizedBox(width: 4),
                                  Text(w.name),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedWalletId = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          InkWell(
            onTap: isSaved
                ? null
                : () async {
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: txDate,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 1),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate == null || !context.mounted) return;

                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(txDate),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    final finalHour = pickedTime?.hour ?? txDate.hour;
                    final finalMinute = pickedTime?.minute ?? txDate.minute;

                    setState(() {
                      _selectedDateTime = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        finalHour,
                        finalMinute,
                      );
                    });
                  },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  const Text('Waktu: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(dateTimeNow, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  if (!isSaved)
                    const Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),

          if (extracted.description != null &&
              extracted.description!.isNotEmpty &&
              (extracted.groups == null || extracted.groups!.length <= 1)) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      extracted.description!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          if (isSaved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.incomeLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.income, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    extracted.groups != null && extracted.groups!.length > 1
                        ? '${extracted.groups!.length} Transaksi Berhasil Dicatat'
                        : 'Transaksi Berhasil Dicatat',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.income,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: () async {
                  ChatMessageModel msgToSave = message;
                  final effectiveTxDate = _selectedDateTime ?? extracted.transactionDate ?? DateTime.now();

                  if (extracted.groups != null && extracted.groups!.length > 1) {
                    final updatedGroups = extracted.groups!.asMap().entries.map((e) {
                      final chosenId = _groupWalletIds[e.key] ?? _selectedWalletId;
                      final chosenName = wallets.where((w) => w.id == chosenId).firstOrNull?.name;
                      return e.value.copyWith(walletId: chosenId, walletName: chosenName);
                    }).toList();
                    msgToSave = message.copyWith(
                      extractedData: extracted.copyWith(
                        groups: updatedGroups,
                        transactionDate: effectiveTxDate,
                      ),
                    );
                  } else {
                    msgToSave = message.copyWith(
                      extractedData: extracted.copyWith(
                        transactionDate: effectiveTxDate,
                      ),
                    );
                  }

                  final savedTxs = await chatProvider.confirmAndSaveTransaction(
                    message: msgToSave,
                    categories: catProvider.categories,
                    walletId: _selectedWalletId,
                    wallets: context.read<WalletProvider>().wallets,
                  );

                  if (context.mounted) {
                    if (savedTxs != null && savedTxs.isNotEmpty) {
                      context.read<TransactionProvider>().insertTransactionsBatchLocally(savedTxs);
                      context.read<WalletProvider>().fetchWallets(forceRefresh: true);
                      final countStr = savedTxs.length > 1
                          ? '${savedTxs.length} transaksi'
                          : 'Transaksi';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$countStr berhasil dicatat ke database!'),
                          backgroundColor: AppColors.income,
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  wasDeletedFromHistory ? Icons.replay_rounded : Icons.check_rounded,
                  size: 16,
                ),
                label: Text(
                  wasDeletedFromHistory
                      ? 'Simpan Ulang ke Transaksi'
                      : (extracted.groups != null && extracted.groups!.length > 1
                          ? 'Simpan Semua (${extracted.groups!.length} Kategori)'
                          : 'Simpan ke Transaksi'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: wasDeletedFromHistory ? AppColors.warning : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
