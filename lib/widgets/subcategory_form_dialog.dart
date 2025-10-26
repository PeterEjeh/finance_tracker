import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/subcategory.dart';
import '../services/subcategory_service.dart';

class SubcategoryFormDialog extends StatefulWidget {
  final String userId;
  final List<Category> categories;
  final Subcategory? subcategory; // null for create, non-null for edit
  final String? initialCategoryId;

  const SubcategoryFormDialog({
    Key? key,
    required this.userId,
    required this.categories,
    this.subcategory,
    this.initialCategoryId,
  }) : super(key: key);

  @override
  State<SubcategoryFormDialog> createState() => _SubcategoryFormDialogState();
}

class _SubcategoryFormDialogState extends State<SubcategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? selectedCategoryId;
  String selectedIcon = 'category';
  Color selectedColor = Colors.blue;
  bool isLoading = false;

  final List<String> availableIcons = [
    'category', 'house', 'build', 'security', 'local_gas_station', 
    'directions_bus', 'car_repair', 'local_parking', 'shopping_cart',
    'restaurant_menu', 'delivery_dining', 'checkroom', 'face',
    'fitness_center', 'movie', 'medical_services', 'local_pharmacy',
    'health_and_safety', 'flash_on', 'water_drop', 'wifi', 'whatshot',
    'school', 'work', 'laptop', 'attach_money', 'savings', 'credit_card'
  ];

  final List<Color> availableColors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
    Colors.pink, Colors.teal, Colors.indigo, Colors.amber, Colors.brown,
    Colors.cyan, Colors.deepOrange, Colors.deepPurple, Colors.lime,
    Colors.lightBlue, Colors.lightGreen,
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.subcategory != null) {
      // Edit mode
      _nameController.text = widget.subcategory!.name;
      _descriptionController.text = widget.subcategory!.description ?? '';
      selectedCategoryId = widget.subcategory!.parentCategoryId;
      selectedIcon = widget.subcategory!.icon;
      selectedColor = widget.subcategory!.color;
    } else {
      // Create mode
      selectedCategoryId = widget.initialCategoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSubcategory() async {
    if (!_formKey.currentState!.validate() || selectedCategoryId == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (widget.subcategory != null) {
        // Update existing subcategory
        await SubcategoryService.updateSubcategory(
          widget.subcategory!.id,
          name: _nameController.text.trim(),
          parentCategoryId: selectedCategoryId,
          icon: selectedIcon,
          colorValue: selectedColor.value,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
        );
      } else {
        // Create new subcategory
        await SubcategoryService.createSubcategory(
          name: _nameController.text.trim(),
          parentCategoryId: selectedCategoryId!,
          icon: selectedIcon,
          colorValue: selectedColor.value,
          userId: widget.userId,
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
        );
      }

      Navigator.of(context).pop(true); // Return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving subcategory: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subcategory != null;
    
    return AlertDialog(
      title: Text(isEdit ? 'Edit Subcategory' : 'Add Subcategory'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Selection
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Parent Category',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categories
                      .where((cat) => cat.type == CategoryType.expense)
                      .map((category) {
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
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a parent category';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 16),

                // Icon Selection
                const Text('Select Icon:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 1,
                    ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = availableIcons[index];
                      final isSelected = selectedIcon == icon;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? selectedColor : Colors.grey,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconData(icon),
                            color: isSelected ? selectedColor : Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Color Selection
                const Text('Select Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableColors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _saveSubcategory,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
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
      case 'savings':
        return Icons.savings;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.category;
    }
  }
}
