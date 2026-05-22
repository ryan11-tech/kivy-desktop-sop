import 'package:flutter/material.dart';

class ContentFormScreen extends StatelessWidget {
  const ContentFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Content form')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const TextField(decoration: InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: 'recipe',
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'recipe', child: Text('Recipe')),
              DropdownMenuItem(value: 'sop', child: Text('SOP')),
            ],
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: 'Content type'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save draft'),
          ),
        ],
      ),
    );
  }
}
