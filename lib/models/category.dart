import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'category.g.dart';

@HiveType(typeId: 3)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  CategoryType type;

  @HiveField(5)
  String userId;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  @HiveField(8)
  bool isDefault;

  @HiveField(9)
  int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorValue,
    required this.type,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  Color get color => Color(colorValue);

  factory Category.create({
    required String name,
    required String icon,
    required Color color,
    required CategoryType type,
    required String userId,
    bool isDefault = false,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      icon: icon,
      colorValue: color.value,
      type: type,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
      sortOrder: sortOrder,
    );
  }

  Category copyWith({
    String? name,
    String? icon,
    Color? color,
    CategoryType? type,
    bool? isDefault,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colorValue: color?.value ?? colorValue,
      type: type ?? this.type,
      userId: userId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorValue': colorValue,
      'type': type.name,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
      'sortOrder': sortOrder,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      colorValue: json['colorValue'] as int,
      type: CategoryType.values.firstWhere((e) => e.name == json['type']),
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDefault: json['isDefault'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  static List<Category> getDefaultCategories(String userId) {
    final now = DateTime.now();

    return [
      // Income Categories
      Category(
        id: 'income_salary',
        name: 'Salary',
        icon: 'work',
        colorValue: Colors.green.value,
        type: CategoryType.income,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
      ),
      Category(
        id: 'income_freelance',
        name: 'Freelance',
        icon: 'laptop',
        colorValue: Colors.blue.value,
        type: CategoryType.income,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
      ),
      Category(
        id: 'income_investment',
        name: 'Investment',
        icon: 'trending_up',
        colorValue: Colors.purple.value,
        type: CategoryType.income,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
      ),
      Category(
        id: 'income_other',
        name: 'Other Income',
        icon: 'attach_money',
        colorValue: Colors.teal.value,
        type: CategoryType.income,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 4,
      ),

      // Expense Categories
      Category(
        id: 'expense_housing',
        name: 'Housing',
        icon: 'home',
        colorValue: Colors.blue.shade700.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
      ),
      Category(
        id: 'expense_transport',
        name: 'Transportation',
        icon: 'directions_car',
        colorValue: Colors.red.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
      ),
      Category(
        id: 'expense_food',
        name: 'Food & Groceries',
        icon: 'restaurant',
        colorValue: Colors.orange.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
      ),
      Category(
        id: 'expense_debt',
        name: 'Debt Payments',
        icon: 'credit_card',
        colorValue: Colors.deepOrange.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 4,
      ),
      Category(
        id: 'expense_savings',
        name: 'Savings & Investments',
        icon: 'savings',
        colorValue: Colors.green.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 5,
      ),
      Category(
        id: 'expense_health',
        name: 'Health & Insurance',
        icon: 'local_hospital',
        colorValue: Colors.red.shade300.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 6,
      ),
      Category(
        id: 'expense_personal',
        name: 'Personal & Lifestyle',
        icon: 'person',
        colorValue: Colors.purple.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 7,
      ),
      Category(
        id: 'expense_education',
        name: 'Education',
        icon: 'school',
        colorValue: Colors.blue.shade700.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 8,
      ),
      Category(
        id: 'expense_family',
        name: 'Family & Relationships',
        icon: 'family_restroom',
        colorValue: Colors.pink.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 9,
      ),
      Category(
        id: 'expense_utilities',
        name: 'Utilities',
        icon: 'bolt',
        colorValue: Colors.amber.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 10,
      ),
      Category(
        id: 'expense_misc',
        name: 'Miscellaneous',
        icon: 'more_horiz',
        colorValue: Colors.grey.value,
        type: CategoryType.expense,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 11,
      ),
    ];
  }
}

@HiveType(typeId: 4)
enum CategoryType {
  @HiveField(0)
  income,
  @HiveField(1)
  expense,
}
