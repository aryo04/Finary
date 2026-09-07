import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cakeu/core/services/supabase_service.dart';
import 'package:cakeu/features/categories/data/models/category_model.dart';

class CategoryRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<CategoryModel>> getCategories() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('categories')
        .select()
        .or('user_id.is.null,user_id.eq.${user.id}')
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    required String color,
    String icon = 'category',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    final response = await _client
        .from('categories')
        .insert({
          'user_id': user.id,
          'name': name,
          'type': type,
          'color': color,
          'icon': icon,
          'is_default': false,
        })
        .select()
        .single();

    return CategoryModel.fromJson(response);
  }

  Future<void> deleteCategory(String categoryId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User belum login');

    await _client
        .from('categories')
        .delete()
        .eq('id', categoryId)
        .eq('user_id', user.id);
  }

  /// Mengambil atau membuat kategori sistem otomatis (misal: Saldo Awal, Penyesuaian Saldo)
  Future<CategoryModel?> getOrCreateSystemCategory({
    required String name,
    required String type,
    required String color,
    String icon = 'category',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final existing = await _client
        .from('categories')
        .select()
        .eq('name', name)
        .eq('type', type)
        .or('user_id.is.null,user_id.eq.${user.id}')
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return CategoryModel.fromJson(existing);
    }

    final inserted = await _client
        .from('categories')
        .insert({
          'user_id': user.id,
          'name': name,
          'type': type,
          'color': color,
          'icon': icon,
          'is_default': true,
        })
        .select()
        .single();

    return CategoryModel.fromJson(inserted);
  }
}
