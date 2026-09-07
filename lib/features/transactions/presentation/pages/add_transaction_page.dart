import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/categories/presentation/providers/category_provider.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/wallets/data/models/wallet_model.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isExpense = true;
  String? _selectedCategoryId;
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
      final wallets = context.read<WalletProvider>().wallets;
      if (wallets.isNotEmpty) {
        setState(() {
          _selectedWalletId = context.read<WalletProvider>().defaultWallet?.id ?? wallets.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _isExpense ? AppColors.expense : AppColors.income,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Bersihkan titik ribuan sebelum parsing double
    final cleanDigits = _amountController.text.replaceAll('.', '').trim();
    final amount = double.tryParse(cleanDigits);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih besar dari 0')),
      );
      return;
    }
    if (amount > 999999999999) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal melebihi batas maksimal transaksi')),
      );
      return;
    }

    final txProvider = context.read<TransactionProvider>();
    final walletProvider = context.read<WalletProvider>();

    final success = await txProvider.addTransaction(
      type: _isExpense ? 'expense' : 'income',
      amount: amount,
      categoryId: _selectedCategoryId,
      walletId: _selectedWalletId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      transactionDate: _selectedDate,
    );

    if (!mounted) return;

    if (success) {
      await walletProvider.fetchWallets(forceRefresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil disimpan!'),
          backgroundColor: AppColors.income,
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txProvider.errorMessage ?? 'Gagal menyimpan transaksi'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final categories =
        _isExpense ? catProvider.expenseCategories : catProvider.incomeCategories;
    final wallets = walletProvider.wallets;

    final activeColor = _isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catat Transaksi'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Sleek Toggle Jenis Transaksi
              _buildTypeToggle(),
              const SizedBox(height: 18),

              // 2. Hero Card Nominal dengan titik ribuan
              _buildHeroAmountCard(activeColor),
              const SizedBox(height: 18),

              // 2.5 Card Pilihan Dompet / Sumber Dana
              _buildWalletField(wallets),
              const SizedBox(height: 14),

              // 3. Card Kategori
              _buildCategoryField(categories),
              const SizedBox(height: 14),

              // 4. Card Keterangan (Opsional)
              _buildDescriptionField(),
              const SizedBox(height: 14),

              // 5. Card Tanggal Transaksi
              _buildDateField(),
              const SizedBox(height: 28),

              // 6. Tombol Simpan Modern
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: txProvider.isLoading ? null : _handleSave,
                  icon: txProvider.isLoading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_rounded, size: 20),
                  label: txProvider.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isExpense ? 'Simpan Pengeluaran' : 'Simpan Pemasukan',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: activeColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Pengeluaran',
              icon: Icons.arrow_upward_rounded,
              isSelected: _isExpense,
              color: AppColors.expense,
              onTap: () {
                setState(() {
                  _isExpense = true;
                  _selectedCategoryId = null;
                });
              },
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Pemasukan',
              icon: Icons.arrow_downward_rounded,
              isSelected: !_isExpense,
              color: AppColors.income,
              onTap: () {
                setState(() {
                  _isExpense = false;
                  _selectedCategoryId = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroAmountCard(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.05),
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
              Icon(Icons.monetization_on_rounded, size: 14, color: activeColor),
              const SizedBox(width: 6),
              Text(
                'NOMINAL ${_isExpense ? "PENGELUARAN" : "PEMASUKAN"}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: activeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Rp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: activeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Masukkan nominal transaksi';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletField(List<WalletModel> wallets) {
    if (wallets.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey('wallet_dropdown_${wallets.length}'),
        initialValue: _selectedWalletId ?? (wallets.isNotEmpty ? wallets.first.id : null),
        decoration: const InputDecoration(
          icon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
          labelText: 'Sumber Dana / Dompet',
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
        items: [
          for (final w in wallets)
            DropdownMenuItem<String>(
              value: w.id,
              child: Row(
                children: [
                  Icon(w.iconData, size: 16, color: w.colorValue),
                  const SizedBox(width: 8),
                  Text(
                    w.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (value) {
          setState(() => _selectedWalletId = value);
        },
      ),
    );
  }

  Widget _buildCategoryField(List<CategoryModel> categories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey('category_dropdown_${_isExpense}_${categories.length}'),
        initialValue: _selectedCategoryId,
        decoration: const InputDecoration(
          icon: Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
          labelText: 'Kategori',
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        hint: const Text(
          'Pilih Kategori',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
        items: [
          for (final cat in categories)
            DropdownMenuItem<String>(
              value: cat.id,
              child: Text(
                cat.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
        ],
        onChanged: (value) {
          setState(() => _selectedCategoryId = value);
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Pilih kategori transaksi';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: _descriptionController,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          icon: Icon(Icons.notes_rounded, color: AppColors.primary, size: 22),
          labelText: 'Keterangan (Opsional)',
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          hintText: 'Contoh: Kopi Kenangan / Beli bensin',
          hintStyle: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppDateFormatter.formatDate(_selectedDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
