import '../models/category.dart';
import '../db/app_database.dart';

class CategoryRepository {
  final _dbInstance = AppDatabase.instance;

  Future<List<Category>> getAllCategories() async {
    final db = await _dbInstance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((e) => Category.fromMap(e)).toList();
  }

  Future<Category> getCategoryById(int id) async {
    final db = await _dbInstance.database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Category.fromMap(result.first);
    }
    throw Exception('Category $id not found');
  }

  Future<int> addCategory(Category category) async {
    final db = await _dbInstance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await _dbInstance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbInstance.database;

    // Check if category is in use
    final count = await db.query(
      'events',
      where: 'category_id = ?',
      whereArgs: [id],
    );
    if (count.isNotEmpty) {
      throw Exception('Cannot delete category. It is currently in use.');
    }

    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
