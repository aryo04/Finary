import 'package:flutter/foundation.dart';
import 'package:cakeu/core/errors/error_handler.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';
import 'package:cakeu/features/categories/data/repositories/category_repository.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  CategoryProvider(this._repository);

  List<CategoryModel> get categories => _categories;
  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();
  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearData() {
    _categories = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    // Jika data kategori sudah ada di memori dan tidak dipaksa refresh, gunakan cache
    if (_categories.isNotEmpty && !forceRefresh) return;

    if (forceRefresh) {
      _categories = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory({
    required String name,
    required String type,
    String icon = 'category',
    String color = '#0D9488',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCat = await _repository.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
      _categories.add(newCat);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      _errorMessage = failure.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
