import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/category_provider.dart';
import '../../data/models/category.dart';

class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse(category.colorHex)),
                  child: const Icon(Icons.category, color: Colors.white),
                ),
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () =>
                          _showAddEditDialog(context, category: category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteCategory(context, category.id!),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedHex = category?.colorHex ?? '0xFF2196F3';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedHex,
                decoration: const InputDecoration(labelText: 'Color'),
                items:
                    [
                          {'name': 'Blue', 'hex': '0xFF2196F3'},
                          {'name': 'Green', 'hex': '0xFF4CAF50'},
                          {'name': 'Red', 'hex': '0xFFF44336'},
                          {'name': 'Orange', 'hex': '0xFFFF9800'},
                          {'name': 'Purple', 'hex': '0xFF9C27B0'},
                        ]
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['hex'],
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: Color(int.parse(c['hex']!)),
                                ),
                                const SizedBox(width: 8),
                                Text(c['name']!),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) selectedHex = val;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final newCat = Category(
                  id: category?.id,
                  name: nameController.text.trim(),
                  colorHex: selectedHex,
                  iconKey: 'category',
                  createdAt: category?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                final provider = context.read<CategoryProvider>();
                if (category == null) {
                  await provider.addCategory(newCat);
                } else {
                  await provider.updateCategory(newCat);
                }

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (!context.mounted) return;
      await context.read<CategoryProvider>().deleteCategory(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category deleted')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}
