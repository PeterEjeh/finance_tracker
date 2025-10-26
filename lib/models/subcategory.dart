import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'subcategory.g.dart';

@HiveType(typeId: 8)
class Subcategory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String parentCategoryId;

  @HiveField(3)
  String icon;

  @HiveField(4)
  int colorValue;

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

  @HiveField(10)
  String? description;

  @HiveField(11)
  bool isActive;

  Subcategory({
    required this.id,
    required this.name,
    required this.parentCategoryId,
    required this.icon,
    required this.colorValue,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.sortOrder = 0,
    this.description,
    this.isActive = true,
  });

  Color get color => Color(colorValue);

  factory Subcategory.create({
    required String name,
    required String parentCategoryId,
    required String icon,
    required Color color,
    required String userId,
    bool isDefault = false,
    int sortOrder = 0,
    String? description,
  }) {
    final now = DateTime.now();
    return Subcategory(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      parentCategoryId: parentCategoryId,
      icon: icon,
      colorValue: color.value,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
      sortOrder: sortOrder,
      description: description,
    );
  }

  Subcategory copyWith({
    String? name,
    String? parentCategoryId,
    String? icon,
    Color? color,
    bool? isDefault,
    int? sortOrder,
    String? description,
    bool? isActive,
  }) {
    return Subcategory(
      id: id,
      name: name ?? this.name,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      icon: icon ?? this.icon,
      colorValue: color?.value ?? colorValue,
      userId: userId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentCategoryId': parentCategoryId,
      'icon': icon,
      'colorValue': colorValue,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
      'sortOrder': sortOrder,
      'description': description,
      'isActive': isActive,
    };
  }

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      parentCategoryId: json['parentCategoryId'],
      icon: json['icon'],
      colorValue: json['colorValue'],
      userId: json['userId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDefault: json['isDefault'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      description: json['description'],
      isActive: json['isActive'] ?? true,
    );
  }

  /// Get default subcategories for specific parent categories
  static List<Subcategory> getDefaultSubcategories(String userId) {
    final now = DateTime.now();

    return [
      // Housing subcategories
      Subcategory(
        id: 'sub_housing_rent',
        name: 'Rent/Mortgage',
        parentCategoryId: 'expense_housing',
        icon: 'house',
        colorValue: Colors.blue.shade800.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
        description: 'Monthly rent or mortgage payments',
      ),
      Subcategory(
        id: 'sub_housing_maintenance',
        name: 'Home Maintenance',
        parentCategoryId: 'expense_housing',
        icon: 'build',
        colorValue: Colors.brown.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
        description: 'Repairs, painting, garden maintenance',
      ),
      Subcategory(
        id: 'sub_housing_insurance',
        name: 'Home Insurance',
        parentCategoryId: 'expense_housing',
        icon: 'security',
        colorValue: Colors.green.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
        description: 'Property insurance premiums',
      ),

      // Transportation subcategories
      Subcategory(
        id: 'sub_transport_fuel',
        name: 'Fuel/Gas',
        parentCategoryId: 'expense_transport',
        icon: 'local_gas_station',
        colorValue: Colors.red.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
        description: 'Vehicle fuel and gas',
      ),
      Subcategory(
        id: 'sub_transport_public',
        name: 'Public Transport',
        parentCategoryId: 'expense_transport',
        icon: 'directions_bus',
        colorValue: Colors.blue.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
        description: 'Bus, train, subway tickets',
      ),
      Subcategory(
        id: 'sub_transport_maintenance',
        name: 'Vehicle Maintenance',
        parentCategoryId: 'expense_transport',
        icon: 'car_repair',
        colorValue: Colors.grey.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
        description: 'Car servicing, repairs, parts',
      ),
      Subcategory(
        id: 'sub_transport_parking',
        name: 'Parking & Tolls',
        parentCategoryId: 'expense_transport',
        icon: 'local_parking',
        colorValue: Colors.amber.shade700.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 4,
        description: 'Parking fees and highway tolls',
      ),

      // Food & Groceries subcategories
      Subcategory(
        id: 'sub_food_groceries',
        name: 'Groceries',
        parentCategoryId: 'expense_food',
        icon: 'shopping_cart',
        colorValue: Colors.green.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
        description: 'Supermarket shopping, household items',
      ),
      Subcategory(
        id: 'sub_food_dining',
        name: 'Dining Out',
        parentCategoryId: 'expense_food',
        icon: 'restaurant_menu',
        colorValue: Colors.orange.shade700.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
        description: 'Restaurants, cafes, takeout',
      ),
      Subcategory(
        id: 'sub_food_delivery',
        name: 'Food Delivery',
        parentCategoryId: 'expense_food',
        icon: 'delivery_dining',
        colorValue: Colors.deepOrange.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
        description: 'Food delivery apps and services',
      ),

      // Personal & Lifestyle subcategories
      Subcategory(
        id: 'sub_personal_clothing',
        name: 'Clothing',
        parentCategoryId: 'expense_personal',
        icon: 'checkroom',
        colorValue: Colors.pink.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
        description: 'Clothes, shoes, accessories',
      ),
      Subcategory(
        id: 'sub_personal_beauty',
        name: 'Beauty & Care',
        parentCategoryId: 'expense_personal',
        icon: 'face',
        colorValue: Colors.purple.shade400.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
        description: 'Haircuts, cosmetics, personal care',
      ),
      Subcategory(
        id: 'sub_personal_fitness',
        name: 'Fitness & Sports',
        parentCategoryId: 'expense_personal',
        icon: 'fitness_center',
        colorValue: Colors.red.shade400.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
        description: 'Gym memberships, sports equipment',
      ),
      Subcategory(
        id: 'sub_personal_entertainment',
        name: 'Entertainment',
        parentCategoryId: 'expense_personal',
        icon: 'movie',
        colorValue: Colors.indigo.shade400.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 4,
        description: 'Movies, games, hobbies, subscriptions',
      ),

      // Health & Insurance subcategories
      Subcategory(
        id: 'sub_health_medical',
        name: 'Medical Expenses',
        parentCategoryId: 'expense_health',
        icon: 'medical_services',
        colorValue: Colors.red.shade400.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
        description: 'Doctor visits, medical procedures',
      ),
      Subcategory(
        id: 'sub_health_pharmacy',
        name: 'Pharmacy & Medicine',
        parentCategoryId: 'expense_health',
        icon: 'local_pharmacy',
        colorValue: Colors.green.shade400.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
        description: 'Prescription drugs, supplements',
      ),
      Subcategory(
        id: 'sub_health_insurance',
        name: 'Health Insurance',
        parentCategoryId: 'expense_health',
        icon: 'health_and_safety',
        colorValue: Colors.blue.shade400.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
        description: 'Health insurance premiums',
      ),

      // Utilities subcategories
      Subcategory(
        id: 'sub_utilities_electricity',
        name: 'Electricity',
        parentCategoryId: 'expense_utilities',
        icon: 'flash_on',
        colorValue: Colors.yellow.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 1,
        description: 'Electric utility bills',
      ),
      Subcategory(
        id: 'sub_utilities_water',
        name: 'Water & Sewer',
        parentCategoryId: 'expense_utilities',
        icon: 'water_drop',
        colorValue: Colors.blue.shade500.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 2,
        description: 'Water and sewerage bills',
      ),
      Subcategory(
        id: 'sub_utilities_internet',
        name: 'Internet & Phone',
        parentCategoryId: 'expense_utilities',
        icon: 'wifi',
        colorValue: Colors.indigo.shade500.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 3,
        description: 'Internet, phone, cable TV',
      ),
      Subcategory(
        id: 'sub_utilities_gas',
        name: 'Gas',
        parentCategoryId: 'expense_utilities',
        icon: 'whatshot',
        colorValue: Colors.orange.shade600.value,
        userId: userId,
        createdAt: now,
        updatedAt: now,
        isDefault: true,
        sortOrder: 4,
        description: 'Natural gas utility bills',
      ),
    ];
  }
}
