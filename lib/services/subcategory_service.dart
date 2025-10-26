import 'package:hive/hive.dart';
import 'dart:ui' as ui;
import '../models/subcategory.dart';
import '../models/category.dart';
import 'database_service.dart';

class SubcategoryService {
  static const String _boxName = 'subcategories';
  static Box<Subcategory>? _box;

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Subcategory>(_boxName);
    } else {
      _box = Hive.box<Subcategory>(_boxName);
    }
  }

  static Box<Subcategory> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('SubcategoryService not initialized. Call init() first.');
    }
    return _box!;
  }

  /// Helper method to get category by ID
  static Category? _getCategoryById(String categoryId) {
    final categories = DatabaseService.instance.getAllCategories();
    return categories.cast<Category?>().firstWhere(
      (cat) => cat?.id == categoryId,
      orElse: () => null,
    );
  }

  /// Create a new subcategory
  static Future<Subcategory> createSubcategory({
    required String name,
    required String parentCategoryId,
    required String icon,
    required int colorValue,
    required String userId,
    String? description,
  }) async {
    // Verify parent category exists
    final category = _getCategoryById(parentCategoryId);
    if (category == null) {
      throw Exception('Parent category not found');
    }

    final subcategory = Subcategory.create(
      name: name,
      parentCategoryId: parentCategoryId,
      icon: icon,
      color: colorValue != null
          ? ui.Color(colorValue)
          : const ui.Color(0x00000000),
      userId: userId,
      description: description,
    );

    await box.put(subcategory.id, subcategory);
    return subcategory;
  }

  /// Get all subcategories for a user
  static Future<List<Subcategory>> getAllSubcategories(String userId) async {
    return box.values
        .where(
          (subcategory) => subcategory.userId == userId && subcategory.isActive,
        )
        .toList()
      ..sort((a, b) {
        // Sort by parent category first, then by sort order
        final categoryCompare = a.parentCategoryId.compareTo(
          b.parentCategoryId,
        );
        if (categoryCompare != 0) return categoryCompare;
        return a.sortOrder.compareTo(b.sortOrder);
      });
  }

  /// Get subcategories for a specific parent category
  static Future<List<Subcategory>> getSubcategoriesForCategory(
    String categoryId,
    String userId,
  ) async {
    return box.values
        .where(
          (subcategory) =>
              subcategory.parentCategoryId == categoryId &&
              subcategory.userId == userId &&
              subcategory.isActive,
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Get a subcategory by ID
  static Future<Subcategory?> getSubcategoryById(String id) async {
    return box.get(id);
  }

  /// Update an existing subcategory
  static Future<Subcategory> updateSubcategory(
    String id, {
    String? name,
    String? parentCategoryId,
    String? icon,
    int? colorValue,
    String? description,
    bool? isActive,
    int? sortOrder,
  }) async {
    final subcategory = box.get(id);
    if (subcategory == null) {
      throw Exception('Subcategory not found');
    }

    // If changing parent category, verify it exists
    if (parentCategoryId != null &&
        parentCategoryId != subcategory.parentCategoryId) {
      final category = _getCategoryById(parentCategoryId);
      if (category == null) {
        throw Exception('New parent category not found');
      }
    }

    final updatedSubcategory = subcategory.copyWith(
      name: name,
      parentCategoryId: parentCategoryId,
      icon: icon,
      color: colorValue != null
          ? ui.Color(colorValue)
          : subcategory.color ?? const ui.Color(0x00000000),
      description: description,
      isActive: isActive,
      sortOrder: sortOrder,
    );

    await box.put(id, updatedSubcategory);
    return updatedSubcategory;
  }

  /// Delete a subcategory (soft delete by setting isActive to false)
  static Future<void> deleteSubcategory(String id) async {
    final subcategory = box.get(id);
    if (subcategory != null) {
      final updatedSubcategory = subcategory.copyWith(isActive: false);
      await box.put(id, updatedSubcategory);
    }
  }

  /// Permanently delete a subcategory
  static Future<void> permanentlyDeleteSubcategory(String id) async {
    await box.delete(id);
  }

  /// Check if a subcategory has any transactions
  static Future<bool> hasTransactions(String subcategoryId) async {
    // This would need to be implemented with your transaction service
    // For now, return false to allow deletion
    return false;
  }

  /// Initialize default subcategories for a user
  static Future<void> initializeDefaultSubcategories(String userId) async {
    final existingSubcategories = await getAllSubcategories(userId);
    if (existingSubcategories.isEmpty) {
      final defaultSubcategories = Subcategory.getDefaultSubcategories(userId);

      for (final subcategory in defaultSubcategories) {
        await box.put(subcategory.id, subcategory);
      }
    }
  }

  /// Get subcategories grouped by parent category
  static Future<Map<String, List<Subcategory>>>
  getSubcategoriesGroupedByCategory(String userId) async {
    final subcategories = await getAllSubcategories(userId);
    final Map<String, List<Subcategory>> grouped = {};

    for (final subcategory in subcategories) {
      if (!grouped.containsKey(subcategory.parentCategoryId)) {
        grouped[subcategory.parentCategoryId] = [];
      }
      grouped[subcategory.parentCategoryId]!.add(subcategory);
    }

    return grouped;
  }

  /// Reorder subcategories within a category
  static Future<void> reorderSubcategories(
    String categoryId,
    List<String> subcategoryIds,
  ) async {
    for (int i = 0; i < subcategoryIds.length; i++) {
      final subcategory = box.get(subcategoryIds[i]);
      if (subcategory != null && subcategory.parentCategoryId == categoryId) {
        final updated = subcategory.copyWith(sortOrder: i + 1);
        await box.put(subcategory.id, updated);
      }
    }
  }

  /// Get expense subcategories only
  static Future<List<Subcategory>> getExpenseSubcategories(
    String userId,
  ) async {
    final categories = DatabaseService.instance.getAllCategories(
      userId: userId,
    );
    final expenseCategoryIds = categories
        .where((cat) => cat.type == CategoryType.expense)
        .map((cat) => cat.id)
        .toSet();

    return box.values
        .where(
          (subcategory) =>
              subcategory.userId == userId &&
              subcategory.isActive &&
              expenseCategoryIds.contains(subcategory.parentCategoryId),
        )
        .toList()
      ..sort((a, b) {
        final categoryCompare = a.parentCategoryId.compareTo(
          b.parentCategoryId,
        );
        if (categoryCompare != 0) return categoryCompare;
        return a.sortOrder.compareTo(b.sortOrder);
      });
  }

  /// Get income subcategories only
  static Future<List<Subcategory>> getIncomeSubcategories(String userId) async {
    final categories = DatabaseService.instance.getAllCategories(
      userId: userId,
    );
    final incomeCategoryIds = categories
        .where((cat) => cat.type == CategoryType.income)
        .map((cat) => cat.id)
        .toSet();

    return box.values
        .where(
          (subcategory) =>
              subcategory.userId == userId &&
              subcategory.isActive &&
              incomeCategoryIds.contains(subcategory.parentCategoryId),
        )
        .toList()
      ..sort((a, b) {
        final categoryCompare = a.parentCategoryId.compareTo(
          b.parentCategoryId,
        );
        if (categoryCompare != 0) return categoryCompare;
        return a.sortOrder.compareTo(b.sortOrder);
      });
  }

  /// Search subcategories by name
  static Future<List<Subcategory>> searchSubcategories(
    String query,
    String userId,
  ) async {
    final normalizedQuery = query.toLowerCase();
    return box.values
        .where(
          (subcategory) =>
              subcategory.userId == userId &&
              subcategory.isActive &&
              subcategory.name.toLowerCase().contains(normalizedQuery),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get subcategory statistics (count, most used, etc.)
  static Future<Map<String, dynamic>> getSubcategoryStats(String userId) async {
    final subcategories = await getAllSubcategories(userId);
    final groupedByCategory = await getSubcategoriesGroupedByCategory(userId);

    return {
      'totalSubcategories': subcategories.length,
      'categoriesWithSubcategories': groupedByCategory.length,
      'averageSubcategoriesPerCategory': groupedByCategory.isEmpty
          ? 0
          : subcategories.length / groupedByCategory.length,
      'subcategoriesByCategory': groupedByCategory.map(
        (categoryId, subs) => MapEntry(categoryId, subs.length),
      ),
    };
  }

  /// Clean up orphaned subcategories (subcategories with deleted parent categories)
  static Future<void> cleanupOrphanedSubcategories(String userId) async {
    final categories = DatabaseService.instance.getAllCategories(
      userId: userId,
    );
    final categoryIds = categories.map((cat) => cat.id).toSet();

    final subcategories = await getAllSubcategories(userId);

    for (final subcategory in subcategories) {
      if (!categoryIds.contains(subcategory.parentCategoryId)) {
        await deleteSubcategory(subcategory.id);
      }
    }
  }
}
