import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';

class CategoryPickerField extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<Category> onSelected;
  final String hintText;
  final CategoryType categoryType;
  final bool enabled;

  const CategoryPickerField({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    this.hintText = 'Select a category',
    this.categoryType = CategoryType.expense,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedCategoryId == null
        ? null
        : categories
              .where((c) => c.id == selectedCategoryId)
              .cast<Category?>()
              .firstOrNull;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? () => _openPicker(context) : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (selected != null) ...[
                CircleAvatar(
                  radius: 10,
                  backgroundColor: selected.color.withOpacity(0.15),
                  child: Icon(
                    _getIconData(selected.icon),
                    size: 14,
                    color: selected.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected.name,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurface,
                ),
              ] else ...[
                Icon(Icons.category, color: theme.colorScheme.onSurface),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hintText,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurface,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            // color replaced below so const is removed
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                // First item: Add custom category action
                if (index == 0) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final userId = AuthService().currentUser?.uid ?? '';
                      final newCategory = await _showAddCategoryDialog(
                        context,
                        userId,
                        categoryType,
                      );
                      if (newCategory != null) {
                        await DatabaseService.instance.addCategory(newCategory);
                        Navigator.pop(context);
                        onSelected(newCategory);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Add custom category',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final category = categories[index - 1];
                final isSelected = category.id == selectedCategoryId;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(category);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (theme.brightness == Brightness.dark
                                ? AppColors.info.withOpacity(0.15)
                                : theme.colorScheme.primary.withOpacity(0.15))
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIconData(category.icon),
                          color: isSelected
                              ? (theme.brightness == Brightness.dark
                                    ? AppColors.info
                                    : theme.colorScheme.primary)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected
                                  ? (theme.brightness == Brightness.dark
                                        ? AppColors.info
                                        : theme.colorScheme.primary)
                                  : theme.colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<Category?> _showAddCategoryDialog(
    BuildContext context,
    String userId,
    CategoryType categoryType,
  ) async {
    final controller = TextEditingController();
    Category? created;

    final iconOptions = [
      'more_horiz',
      'home',
      'directions_car',
      'restaurant',
      'credit_card',
      'savings',
      'work',
      'laptop',
      'trending_up',
      'attach_money',
      'movie',
      'receipt',
      'local_hospital',
      'school',
      'flight',
      'person',
      'family_restroom',
      'bolt',
      'shopping_bag',
    ];

    final colorOptions = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.grey,
      Colors.brown,
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String selectedIcon = 'more_horiz';
        Color selectedColor = Colors.grey;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: const Text(
                'New Category',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category name',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A7A7A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.only(top: 12, bottom: 6),
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Icon',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A7A7A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: iconOptions.map((iconName) {
                        final isSelected = iconName == selectedIcon;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = iconName),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withOpacity(0.15)
                                  : const Color.fromARGB(0, 0, 16, 110),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                _getIconData(iconName),
                                color: isSelected
                                    ? selectedColor
                                    : const Color(0xFF6F6F6F),
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Color',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7A7A7A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 20,
                      runSpacing: 14,
                      children: colorOptions.map((c) {
                        final isSelected = c.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 2,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF6F6F6F)),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        elevation: 6,
                      ),
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isEmpty) return;
                        created = Category.create(
                          name: name,
                          icon: selectedIcon,
                          color: selectedColor,
                          type: categoryType,
                          userId: userId,
                        );
                        Navigator.of(ctx).pop();
                      },
                      child: Text(
                        'Add',
                        style: TextStyle(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    return created;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'work':
        return Icons.work;
      case 'laptop':
        return Icons.laptop;
      case 'trending_up':
        return Icons.trending_up;
      case 'attach_money':
        return Icons.attach_money;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'receipt':
        return Icons.receipt;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'flight':
        return Icons.flight;
      case 'more_horiz':
        return Icons.more_horiz;
      case 'home':
        return Icons.home;
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'person':
        return Icons.person;
      case 'family_restroom':
        return Icons.family_restroom;
      case 'bolt':
        return Icons.bolt;
      default:
        return Icons.category;
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
