import 'package:flutter/foundation.dart';
import 'package:cakeu/core/errors/error_handler.dart';
import 'package:cakeu/core/utils/currency_formatter.dart';
import 'package:cakeu/features/categories/data/repositories/category_repository.dart';
import 'package:cakeu/features/transactions/data/repositories/transaction_repository.dart';
import 'package:cakeu/features/wallets/data/models/wallet_model.dart';
import 'package:cakeu/features/wallets/data/models/wallet_transfer_model.dart';
import 'package:cakeu/features/wallets/data/repositories/wallet_repository.dart';

class WalletProvider with ChangeNotifier {
  final WalletRepository _repository;
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;

  VoidCallback? onTransactionsChanged;
  bool _isMigrating = false;

  List<WalletModel> _wallets = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedWalletId; // Digunakan jika ingin memfilter data per dompet

  WalletProvider({
    WalletRepository? repository,
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
  })  : _repository = repository ?? WalletRepository(),
        _transactionRepository = transactionRepository ?? TransactionRepository(),
        _categoryRepository = categoryRepository ?? CategoryRepository();

  List<WalletModel> get wallets => _wallets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedWalletId => _selectedWalletId;

  WalletModel? get selectedWallet =>
      _wallets.where((w) => w.id == _selectedWalletId).firstOrNull;

  WalletModel? get defaultWallet =>
      _wallets.where((w) => w.isDefault).firstOrNull ?? _wallets.firstOrNull;

  double get totalWealth =>
      _wallets.fold(0.0, (sum, w) => sum + w.currentBalance);

  /// Menyesuaikan saldo dompet & total kekayaan secara instan di memori lokal saat transaksi ditambah/dihapus
  void adjustWalletBalance({
    required String? walletId,
    required double amount,
    required String type,
    required bool isAddition,
  }) {
    final targetId = walletId ?? defaultWallet?.id;
    if (targetId == null) return;

    final index = _wallets.indexWhere((w) => w.id == targetId);
    if (index == -1) return;

    final current = _wallets[index];
    double delta = 0.0;
    if (type == 'income') {
      delta = isAddition ? amount : -amount;
    } else {
      delta = isAddition ? -amount : amount;
    }

    _wallets[index] = current.copyWith(currentBalance: current.currentBalance + delta);
    notifyListeners();
  }

  void clearData() {
    _wallets = [];
    _isLoading = false;
    _error = null;
    _selectedWalletId = null;
    notifyListeners();
  }

  Future<void> fetchWallets({bool forceRefresh = false}) async {
    if (_wallets.isNotEmpty && !forceRefresh && !_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallets = await _repository.getWallets();
      _isLoading = false;
      notifyListeners();

      // Migrasi otomatis dompet lama yang masih memiliki initial_balance > 0
      if (!_isMigrating) {
        await _migrateInitialBalancesIfNeeded();
      }
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _error = failure.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Migrasi otomatis untuk dompet yang masih memiliki initial_balance > 0 agar dicatat sebagai transaksi Pemasukan Saldo Awal resmi
  Future<void> _migrateInitialBalancesIfNeeded() async {
    final walletsWithInitial = _wallets.where((w) => w.initialBalance > 0).toList();
    if (walletsWithInitial.isEmpty) return;

    _isMigrating = true;
    try {
      final saldoAwalCat = await _categoryRepository.getOrCreateSystemCategory(
        name: 'Saldo Awal',
        type: 'income',
        color: '#0D9488',
        icon: 'account_balance_wallet',
      );

      bool migratedAny = false;
      for (final wallet in walletsWithInitial) {
        final amount = wallet.initialBalance;
        if (amount <= 0) continue;

        // 1. Buat transaksi pemasukan resmi untuk Saldo Awal
        await _transactionRepository.addTransaction(
          type: 'income',
          amount: amount,
          categoryId: saldoAwalCat?.id,
          walletId: wallet.id,
          description: 'Saldo Awal ${wallet.name}',
          transactionDate: DateTime.now(),
          source: 'system',
        );

        // 2. Set initial_balance dompet menjadi 0
        await _repository.updateWallet(
          id: wallet.id,
          initialBalance: 0.0,
        );
        migratedAny = true;
      }

      if (migratedAny) {
        onTransactionsChanged?.call();
        _wallets = await _repository.getWallets();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Gagal migrasi saldo awal: $e');
    } finally {
      _isMigrating = false;
    }
  }

  void selectWallet(String? walletId) {
    if (_selectedWalletId == walletId) {
      _selectedWalletId = null; // Unselect / show all
    } else {
      _selectedWalletId = walletId;
    }
    notifyListeners();
  }

  Future<bool> createWallet({
    required String name,
    required String type,
    double initialBalance = 0.0,
    String icon = 'account_balance_wallet',
    String color = '#0D9488',
    bool isDefault = false,
  }) async {
    try {
      // 1. Buat dompet selalu dengan initialBalance = 0.0 agar tidak terhitung ganda
      final newWallet = await _repository.createWallet(
        name: name,
        type: type,
        initialBalance: 0.0,
        icon: icon,
        color: color,
        isDefault: isDefault,
      );

      // 2. Jika ada saldo awal > 0, catat sebagai transaksi Pemasukan Saldo Awal
      if (initialBalance > 0) {
        final saldoAwalCat = await _categoryRepository.getOrCreateSystemCategory(
          name: 'Saldo Awal',
          type: 'income',
          color: '#0D9488',
          icon: 'account_balance_wallet',
        );

        await _transactionRepository.addTransaction(
          type: 'income',
          amount: initialBalance,
          categoryId: saldoAwalCat?.id,
          walletId: newWallet.id,
          description: 'Saldo Awal $name',
          transactionDate: DateTime.now(),
          source: 'system',
        );

        onTransactionsChanged?.call();
      }

      _wallets.add(newWallet);
      notifyListeners();
      await fetchWallets(forceRefresh: true);
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _error = failure.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWallet({
    required String id,
    String? name,
    String? type,
    double? initialBalance,
    String? icon,
    String? color,
    bool? isDefault,
  }) async {
    try {
      final updated = await _repository.updateWallet(
        id: id,
        name: name,
        type: type,
        initialBalance: initialBalance,
        icon: icon,
        color: color,
        isDefault: isDefault,
      );
      final index = _wallets.indexWhere((w) => w.id == id);
      if (index != -1) {
        _wallets[index] = updated;
      }
      notifyListeners();
      await fetchWallets(forceRefresh: true);
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _error = failure.message;
      notifyListeners();
      return false;
    }
  }

  /// Menyesuaikan saldo riil dompet dengan mencatat transaksi penyesuaian (koreksi selisih)
  Future<bool> setWalletBalance({
    required String walletId,
    required double targetBalance,
  }) async {
    final wallet = _wallets.where((w) => w.id == walletId).firstOrNull;
    if (wallet == null) return false;

    final delta = targetBalance - wallet.currentBalance;
    if (delta.abs() < 0.01) return true;

    try {
      if (delta > 0) {
        // Selisih positif -> pemasukan
        final cat = await _categoryRepository.getOrCreateSystemCategory(
          name: 'Penyesuaian Saldo',
          type: 'income',
          color: '#6B7280',
          icon: 'tune',
        );

        await _transactionRepository.addTransaction(
          type: 'income',
          amount: delta,
          categoryId: cat?.id,
          walletId: walletId,
          description: 'Penyesuaian Saldo ${wallet.name} (+${CurrencyFormatter.formatRupiah(delta)})',
          transactionDate: DateTime.now(),
          source: 'adjustment',
        );
      } else {
        // Selisih negatif -> pengeluaran
        final cat = await _categoryRepository.getOrCreateSystemCategory(
          name: 'Penyesuaian Saldo',
          type: 'expense',
          color: '#6B7280',
          icon: 'tune',
        );

        await _transactionRepository.addTransaction(
          type: 'expense',
          amount: delta.abs(),
          categoryId: cat?.id,
          walletId: walletId,
          description: 'Penyesuaian Saldo ${wallet.name} (-${CurrencyFormatter.formatRupiah(delta.abs())})',
          transactionDate: DateTime.now(),
          source: 'adjustment',
        );
      }

      onTransactionsChanged?.call();
      await fetchWallets(forceRefresh: true);
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _error = failure.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWallet(String id) async {
    try {
      await _repository.deleteWallet(id);
      _wallets.removeWhere((w) => w.id == id);
      if (_selectedWalletId == id) _selectedWalletId = null;
      notifyListeners();
      await fetchWallets(forceRefresh: true);
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _error = failure.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> transferFunds({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? description,
    DateTime? date,
  }) async {
    try {
      await _repository.transferFunds(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        description: description,
        date: date,
      );
      await fetchWallets(forceRefresh: true);
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _error = failure.message;
      notifyListeners();
      return false;
    }
  }

  Future<List<WalletTransferModel>> getTransfers() async {
    return await _repository.getTransfers();
  }

  Future<bool> deleteTransfer(String transferId) async {
    try {
      await _repository.deleteTransfer(transferId);
      await fetchWallets(forceRefresh: true);
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _error = failure.message;
      notifyListeners();
      return false;
    }
  }
}
