import 'package:flutter/material.dart';

import '../../core/models/category.dart';
import '../../core/models/content_item.dart';
import '../../core/models/parameter.dart';
import '../../core/models/recipe_variant.dart';
import '../../theme/app_colors.dart';
import '../../widgets/content_chips.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({
    required this.item,
    required this.category,
    required this.isFavorite,
    required this.onFavoriteChanged,
    super.key,
  });

  final ContentItem item;
  final Category? category;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late bool _isFavorite = widget.isFavorite;
  int _servings = 1;
  String? _selectedVariantKey;

  @override
  void initState() {
    super.initState();
    _selectedVariantKey = widget.item.recipe.variants.isEmpty
        ? null
        : widget.item.recipe.variants.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: <Widget>[
          IconButton(
            tooltip: _isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? AppColors.favorite : null,
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            widget.category?.name ?? 'Uncategorized',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.gold),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              ContentTypeChip(item: item),
              const SizedBox(width: 8),
              StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 16),
          if (item.notes.isNotEmpty)
            Text(item.notes, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          if (item.isRecipe)
            _RecipeDetail(
              item: item,
              servings: _servings,
              selectedVariantKey: _selectedVariantKey,
            ),
          if (item.isSop) _SopDetail(item: item),
        ],
      ),
      bottomNavigationBar: item.isRecipe
          ? _RecipeBottomBar(
              servings: _servings,
              onChanged: (value) => setState(() => _servings = value),
              item: item,
              selectedVariantKey: _selectedVariantKey,
              onVariantChanged: (key) =>
                  setState(() => _selectedVariantKey = key),
            )
          : null,
    );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteChanged(_isFavorite);
  }
}

class _RecipeBottomBar extends StatelessWidget {
  const _RecipeBottomBar({
    required this.servings,
    required this.onChanged,
    required this.item,
    required this.selectedVariantKey,
    required this.onVariantChanged,
  });

  final int servings;
  final ValueChanged<int> onChanged;
  final ContentItem item;
  final String? selectedVariantKey;
  final ValueChanged<String> onVariantChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Decrease servings',
                onPressed: servings == 1 ? null : () => onChanged(servings - 1),
                icon: const Icon(Icons.remove),
              ),
              Text('x$servings'),
              IconButton(
                tooltip: 'Increase servings',
                onPressed: servings == 99
                    ? null
                    : () => onChanged(servings + 1),
                icon: const Icon(Icons.add),
              ),
              const Spacer(),
              if (item.recipe.variants.isNotEmpty)
                DropdownButton<String>(
                  value: selectedVariantKey,
                  items: item.recipe.variants
                      .map(
                        (variant) => DropdownMenuItem<String>(
                          value: variant.key,
                          child: Text(variant.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onVariantChanged(value);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeDetail extends StatelessWidget {
  const _RecipeDetail({
    required this.item,
    required this.servings,
    required this.selectedVariantKey,
  });

  final ContentItem item;
  final int servings;
  final String? selectedVariantKey;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedVariant(item);
    final parameters = selected?.parameters ?? item.recipe.parameters;
    final steps = selected?.steps ?? item.recipe.steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.recipe.recipeType.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        _ParameterTable(
          parameters: parameters
              .map((parameter) => parameter.scaledBy(servings))
              .toList(),
        ),
        const SizedBox(height: 24),
        _StepsList(steps: steps),
      ],
    );
  }

  RecipeVariant? _selectedVariant(ContentItem item) {
    if (item.recipe.variants.isEmpty) {
      return null;
    }

    return item.recipe.variants.firstWhere(
      (variant) => variant.key == selectedVariantKey,
      orElse: () => item.recipe.variants.first,
    );
  }
}

class _SopDetail extends StatelessWidget {
  const _SopDetail({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.sop.sopType.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        _ParameterTable(parameters: item.sop.parameters),
        const SizedBox(height: 24),
        _StepsList(steps: item.sop.steps),
      ],
    );
  }
}

class _ParameterTable extends StatelessWidget {
  const _ParameterTable({required this.parameters});

  final List<Parameter> parameters;

  @override
  Widget build(BuildContext context) {
    if (parameters.isEmpty) {
      return const Text('No quantities yet.');
    }

    return Card(
      child: Column(
        children: parameters
            .map(
              (parameter) => ListTile(
                title: Text(parameter.name),
                trailing: Text(
                  '${parameter.formattedAmount} ${parameter.unit}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StepsList extends StatelessWidget {
  const _StepsList({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const Text('No steps yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Steps', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...steps.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text('${entry.$1 + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.$2)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
