import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

// Add custom snackbar function at the top level
void showCustomSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onActionPressed,
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isError ? Colors.red[400] : Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 14,
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onActionPressed ?? () {},
            )
          : null,
    ),
  );
}

class ExpenseCategories extends StatefulWidget {
  const ExpenseCategories({super.key});

  @override
  State<ExpenseCategories> createState() => _ExpenseCategoriesState();
}

class _ExpenseCategoriesState extends State<ExpenseCategories> {
  final DatabaseReference _database = FirebaseDatabase.instance
      .ref()
      .child('shop_management/shop_1/expenses');

  final TextEditingController _categoryController = TextEditingController();
  Map<String, String> categories = {};
  bool _isEditing = false;
  String? _editingKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void _fetchCategories() {
    setState(() => _isLoading = true);
    _database.child('categories').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          categories =
              data.map((key, value) => MapEntry(key, value.toString()));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _deleteCategory(String key) async {
    try {
      // First check if the category is used in any expenses
      final expensesSnapshot = await _database
          .child('records')
          .orderByChild('category')
          .equalTo(categories[key])
          .get();

      if (expensesSnapshot.exists) {
        if (mounted) {
          showCustomSnackBar(
            context,
            message:
                'Cannot delete category as it is used in existing expenses',
            isError: true,
          );
        }
        return;
      }

      await _database.child('categories/$key').remove();
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Category deleted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Error deleting category: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.trim().isEmpty) {
      showCustomSnackBar(
        context,
        message: 'Please enter a category name',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final categoryName = _categoryController.text.trim().toLowerCase();
      final categoryKey = categoryName.replaceAll(' ', '_');

      if (_isEditing && _editingKey != null) {
        await _database.child('categories/$_editingKey').set(categoryName);
        setState(() {
          _isEditing = false;
          _editingKey = null;
        });
        if (mounted) {
          showCustomSnackBar(
            context,
            message: 'Category updated successfully',
          );
        }
      } else {
        if (categories.values.contains(categoryName)) {
          setState(() => _isLoading = false);
          if (mounted) {
            showCustomSnackBar(
              context,
              message: 'Category already exists',
              isError: true,
            );
          }
          return;
        }
        await _database.child('categories/$categoryKey').set(categoryName);
        if (mounted) {
          showCustomSnackBar(
            context,
            message: 'Category added successfully',
          );
        }
      }
      _categoryController.clear();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context,
          message: 'Error saving category: $e',
          isError: true,
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Categories',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _categoryController,
                      decoration: InputDecoration(
                        labelText:
                            _isEditing ? 'Edit Category' : 'Add Category',
                        hintText: 'Enter category name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isEditing)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _editingKey = null;
                                    _categoryController.clear();
                                  });
                                },
                              ),
                            IconButton(
                              icon: Icon(_isEditing ? Icons.check : Icons.add),
                              onPressed: _isLoading ? null : _addCategory,
                            ),
                          ],
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addCategory(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : categories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Categories',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a category to get started',
                              style: TextStyle(
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final key = categories.keys.elementAt(index);
                          final category = categories[key]!;
                          return Dismissible(
                            key: Key(key),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text(
                                      'Are you sure you want to delete "$category"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) => _deleteCategory(key),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(15),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                              ),
                            ),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  category.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                      _editingKey = key;
                                      _categoryController.text = category;
                                    });
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }
}
