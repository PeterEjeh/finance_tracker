import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../services/database_service.dart';
import '../services/subcategory_service.dart';

class SubcategorySelector extends StatefulWidget {
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final String userId;
  final CategoryType? categoryType;
  final Function(String?, String?) onSelectionChanged; // (categoryId, subcategoryId)
  final bool allowNoSubcategory;
  final String noSubcategoryText;

  const SubcategorySelector({
    Key? key,
    this.selectedCategoryId,
    this.selectedSubcategoryId,
    required this.userId,
    this.categoryType,
    required this.onSelectionChanged,
    this.allowNoSubcategory = true,
    this.noSubcategoryText = 'No subcategory',
  }) : super(key: key);

  @override
  State<SubcategorySelector> createState() => _SubcategorySelectorState();
}

class _SubcategorySelectorState extends State<SubcategorySelector> {
  List<Category> categories = [];
  Map<String, List<Subcategory>> subcategoriesByCategory = {};
  bool isLoading = true;
  String? selectedCategoryId;
  String? selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.selectedCategoryId;
    selectedSubcategoryId = widget.selectedSubcategoryId;
    _loadData();
  }

  @override
  void didUpdateWidget(SubcategorySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryId != widget.selectedCategoryId ||
        oldWidget.selectedSubcategoryId != widget.selectedSubcategoryId) {
      selectedCategoryId = widget.selectedCategoryId;
      selectedSubcategoryId = widget.selectedSubcategoryId;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load categories
      final allCategories = DatabaseService.instance.getAllCategories(userId: widget.userId);
      
      if (widget.categoryType != null) {
        categories = allCategories
            .where((cat) => cat.type == widget.categoryType)
            .toList();
      } else {
        categories = allCategories;
      }

      // Load subcategories grouped by category
      subcategoriesByCategory = await SubcategoryService.getSubcategoriesGroupedByCategory(widget.userId);

    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
      selectedSubcategoryId = null; // Reset subcategory when category changes
    });
    widget.onSelectionChanged(categoryId, null);
  }

  void _onSubcategoryChanged(String? subcategoryId) {
    setState(() {
      selectedSubcategoryId = subcategoryId;
    });
    widget.onSelectionChanged(selectedCategoryId, subcategoryId);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Dropdown
        DropdownButtonFormField<String>(
          value: selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Row(
                children: [
                  Icon(
                    _getIconData(category.icon),
                    color: category.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: _onCategoryChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),

        // Subcategory Dropdown (only show when category is selected)
        if (selectedCategoryId != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedSubcategoryId,
            decoration: const InputDecoration(
              labelText: 'Subcategory (Optional)',
              border: OutlineInputBorder(),
            ),
            items: _buildSubcategoryItems(),
            onChanged: _onSubcategoryChanged,
          ),
        ],
      ],
    );
  }

  List<DropdownMenuItem<String>> _buildSubcategoryItems() {
    if (selectedCategoryId == null) return [];

    final subcategories = subcategoriesByCategory[selectedCategoryId] ?? [];
    final items = <DropdownMenuItem<String>>[];

    // Add "No subcategory" option if allowed
    if (widget.allowNoSubcategory) {
      items.add(
        DropdownMenuItem<String>(
          value: null,
          child: Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.noSubcategoryText,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Add subcategory options
    items.addAll(
      subcategories.map((subcategory) {
        return DropdownMenuItem<String>(
          value: subcategory.id,
          child: Row(
            children: [
              Icon(
                _getIconData(subcategory.icon),
                color: subcategory.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(subcategory.name),
              ),
            ],
          ),
        );
      }),
    );

    return items;
  }

  IconData _getIconData(String iconName) {
    // Map string icon names to IconData
    // This is a simplified version - you might want to expand this
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'directions_car':
        return Icons.directions_car;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'person':
        return Icons.person;
      case 'school':
        return Icons.school;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'bolt':
        return Icons.bolt;
      case 'work':
        return Icons.work;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'house':
        return Icons.house;
      case 'build':
        return Icons.build;
      case 'security':
        return Icons.security;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'car_repair':
        return Icons.car_repair;
      case 'local_parking':
        return Icons.local_parking;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'delivery_dining':
        return Icons.delivery_dining;
      case 'checkroom':
        return Icons.checkroom;
      case 'face':
        return Icons.face;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'movie':
        return Icons.movie;
      case 'medical_services':
        return Icons.medical_services;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'flash_on':
        return Icons.flash_on;
      case 'water_drop':
        return Icons.water_drop;
      case 'wifi':
        return Icons.wifi;
      case 'whatshot':
        return Icons.whatshot;
      default:
        return Icons.category;
    }
  }
}
