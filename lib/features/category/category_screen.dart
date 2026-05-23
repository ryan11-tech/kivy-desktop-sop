import 'package:flutter/material.dart';

import '../../core/models/category.dart';
import '../../core/models/content_item.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    required this.category,
    required this.items,
    super.key,
  });

  final Category category;
  final List<ContentItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: Icon(
                item.isRecipe ? Icons.local_cafe : Icons.assignment_outlined,
              ),
              title: Text(item.name),
              subtitle: Text(item.previewText),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
