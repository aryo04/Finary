import 'package:flutter/foundation.dart';
import 'package:cakeu/core/errors/error_handler.dart';
import 'package:cakeu/features/transactions/data/models/transaction_model.dart';
import 'package:cakeu/features/transactions/data/repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final TransactionRepository _repository;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  String? _errorMessage;
  String? _filterWalletId; // Filter transaksi per dompet
  void Function(String id)? onTransactionDeleted;

  TransactionProvider(this._repository);

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  String? get errorMessage => _errorMessage;
  String? get filterWalletId => _filterWalletId;

  List<TransactionModel> get filteredTransactions {
    if (_filterWalletId == null || _filterWalletId!.isEmpty) {
      return _transactions;
    }
    return _transactions.where((t) => t.walletId == _filterWalletId).toList();
  }

  double get totalIncome {
    final list = _filterWalletId != null ? filteredTransactions : _transactions;
    return list
        .where((t) => t.isIncome)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    final list = _filterWalletId != null ? filteredTransactions : _transactions;
    return list
        .where((t) => t.isExpense)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get balance => totalIncome - totalExpense;

  void setFilterWallet(String? walletId) {
    if (_filterWalletId == walletId) {
      _filterWalletId = null; // Unselect -> All
    } else {
      _filterWalletId = walletId;
    }
    notifyListeners();
  }

  void clearData() {
    _transactions = [];
    _hasLoadedOnce = false;
    _errorMessage = null;
    _filterWalletId = null;
    notifyListeners();
  }

  /// GET: Fetch data dengan in-memory cache jika sudah pernah dimuat
  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    if (_hasLoadedOnce && !forceRefresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fresh = await _repository.getTransactions();
      _transactions = fresh;
      _hasLoadedOnce = true;
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _errorMessage = ErrorHandler.handle(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Memasukkan data transaksi langsung ke cache lokal tanpa menunggu fetch ulang
  void insertTransactionLocally(TransactionModel tx) {
    _transactions.removeWhere((t) => t.id == tx.id);
    _transactions.insert(0, tx);
    _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    _hasLoadedOnce = true;
    notifyListeners();
  }

  /// Memasukkan sekumpulan transaksi langsung ke cache lokal
  void insertTransactionsBatchLocally(List<TransactionModel> txs) {
    for (final tx in txs) {
      _transactions.removeWhere((t) => t.id == tx.id);
      _transactions.insert(0, tx);
    }
    _transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    _hasLoadedOnce = true;
    notifyListeners();
  }

  /// PUSH / INSERT: Menambahkan data baru langsung ke urutan teratas secara instan
  Future<bool> addTransaction({
    required String type,
    required double amount,
    String? categoryId,
    String? walletId,
    String? description,
    required DateTime transactionDate,
    String source = 'manual',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTx = await _repository.addTransaction(
        type: type,
        amount: amount,
        categoryId: categoryId,
        walletId: walletId,
        description: description,
        transactionDate: transactionDate,
        source: source,
      );

      _transactions.insert(0, newTx);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _errorMessage = ErrorHandler.handle(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// BATCH INSERT: Menambahkan sekumpulan transaksi hasil ekstraksi AI
  Future<bool> addTransactionsBatch(List<Map<String, dynamic>> items) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTxs = await _repository.addTransactionsBatch(items);
      for (final tx in newTxs.reversed) {
        _transactions.insert(0, tx);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _errorMessage = ErrorHandler.handle(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// UPDATE: Memperbarui data transaksi lokal & cloud
  Future<bool> updateTransaction({
    required String id,
    required String type,
    required double amount,
    String? categoryId,
    String? walletId,
    String? description,
    required DateTime transactionDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedTx = await _repository.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        categoryId: categoryId,
        walletId: walletId,
        description: description,
        transactionDate: transactionDate,
      );

      final index = _transactions.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transactions[index] = updatedTx;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _errorMessage = ErrorHandler.handle(e, stackTrace).message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// DELETE: Menghapus data transaksi secara instan (Optimistic UI)
  Future<bool> deleteTransaction(String id) async {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return false;

    final removedTx = _transactions[index];
    // 1. Langsung hapus dari list lokal agar Dismissible tidak crash dengan red error
    _transactions.removeAt(index);
    _errorMessage = null;
    notifyListeners();

    // Notifikasi listener eksternal (misal: sinkronisasi chatbot)
    onTransactionDeleted?.call(id);

    try {
      // 2. Hapus dari database Supabase
      await _repository.deleteTransaction(id, type: removedTx.type);
      return true;
    } catch (e, stackTrace) {
      // 3. Rollback jika ada kegagalan jaringan / server
      _transactions.insert(index, removedTx);
      _errorMessage = ErrorHandler.handle(e, stackTrace).message;
      notifyListeners();
      return false;
    }
  }
}
