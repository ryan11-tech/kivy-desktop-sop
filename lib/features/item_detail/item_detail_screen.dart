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
    required this.isFavorite,
    required this.onFavoriteChanged,
    this.category,
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
    _selectedVariantKey =
        widget.item.recipe.variants.isEmpty
            ? null
            : widget.item.recipe.variants.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.category != null)
              Text(
                widget.category!.name,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            Text(
              item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? AppColors.favorite : Colors.white54,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
        children: [
          // Type chip + meta
          Row(
            children: [
              ContentTypeChip(item: item),
              const SizedBox(width: 8),
              StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 12),

          // Notes
          if (item.notes.isNotEmpty) ...[
            Text(
              item.notes,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 12),
          ],

          // Serving stepper
          if (item.isRecipe) ...[
            _ServingStepper(
              servings: _servings,
              onMinus:
                  () =>
                      setState(() => _servings = (_servings - 1).clamp(1, 99)),
              onPlus:
                  () =>
                      setState(() => _servings = (_servings + 1).clamp(1, 99)),
              onReset: () => setState(() => _servings = 1),
            ),
            const SizedBox(height: 16),
          ],

          // Recipe content
          if (item.isRecipe)
            _RecipeDetail(
              item: item,
              servings: _servings,
              selectedVariantKey: _selectedVariantKey,
              onVariantChanged:
                  (key) => setState(() => _selectedVariantKey = key),
            ),

          // SOP content
          if (item.isSop) _SopDetail(item: item),
        ],
      ),
    );
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    widget.onFavoriteChanged(_isFavorite);
  }
}

// ── Serving Stepper ───────────────────────────────────────────────────────────

class _ServingStepper extends StatelessWidget {
  const _ServingStepper({
    required this.servings,
    required this.onMinus,
    required this.onPlus,
    required this.onReset,
  });

  final int servings;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text(
            'Serving',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const Spacer(),
          _StepperBtn(icon: Icons.remove, onTap: servings > 1 ? onMinus : null),
          const SizedBox(width: 12),
          Text(
            'x$servings',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          _StepperBtn(
            icon: Icons.add,
            onTap: servings < 99 ? onPlus : null,
            filled: true,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  const _StepperBtn({required this.icon, this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 20,
          color:
              onTap == null
                  ? Colors.white24
                  : filled
                  ? Colors.white
                  : AppColors.primary,
        ),
      ),
    );
  }
}

// ── Recipe Detail ─────────────────────────────────────────────────────────────

class _RecipeDetail extends StatelessWidget {
  const _RecipeDetail({
    required this.item,
    required this.servings,
    required this.selectedVariantKey,
    required this.onVariantChanged,
  });

  final ContentItem item;
  final int servings;
  final String? selectedVariantKey;
  final ValueChanged<String> onVariantChanged;

  @override
  Widget build(BuildContext context) {
    final selected =
        item.recipe.variants.isEmpty
            ? null
            : item.recipe.variants.firstWhere(
              (v) => v.key == selectedVariantKey,
              orElse: () => item.recipe.variants.first,
            );

    final parameters = selected?.parameters ?? item.recipe.parameters;
    final steps = selected?.steps ?? item.recipe.steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Variant pill tabs
        if (item.recipe.variants.isNotEmpty) ...[
          _VariantTabs(
            variants: item.recipe.variants,
            selectedKey: selectedVariantKey,
            onSelect: onVariantChanged,
          ),
          const SizedBox(height: 16),
        ],

        // Parameters
        if (parameters.isNotEmpty) ...[
          const _SectionHeader(text: 'PARAMETERS'),
          const SizedBox(height: 8),
          _ParameterTable(
            parameters: parameters.map((p) => p.scaledBy(servings)).toList(),
            accent:
                selected == null
                    ? AppColors.primary
                    : selected.key == 'hot'
                    ? AppColors.hot
                    : AppColors.cold,
          ),
          const SizedBox(height: 20),
        ],

        // Steps
        if (steps.isNotEmpty) ...[
          const _SectionHeader(text: 'STEPS'),
          const SizedBox(height: 8),
          _StepsList(steps: steps),
        ],

        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Measure all ingredients accurately.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ── Variant Tabs ──────────────────────────────────────────────────────────────

class _VariantTabs extends StatelessWidget {
  const _VariantTabs({
    required this.variants,
    required this.selectedKey,
    required this.onSelect,
  });

  final List<RecipeVariant> variants;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          variants.map((variant) {
            final isSelected = variant.key == selectedKey;
            final accent =
                variant.key == 'hot' ? AppColors.hot : AppColors.cold;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(variant.key),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    variant.name.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

// ── SOP Detail ────────────────────────────────────────────────────────────────

class _SopDetail extends StatelessWidget {
  const _SopDetail({required this.item});

  final ContentItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.sop.sopType.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.sop.sopType.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (item.sop.parameters.isNotEmpty) ...[
          const _SectionHeader(text: 'PARAMETERS'),
          const SizedBox(height: 8),
          _ParameterTable(parameters: item.sop.parameters),
          const SizedBox(height: 20),
        ],
        if (item.sop.steps.isNotEmpty) ...[
          const _SectionHeader(text: 'STEPS'),
          const SizedBox(height: 8),
          _StepsList(steps: item.sop.steps),
        ],
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── Parameter Table ───────────────────────────────────────────────────────────

class _ParameterTable extends StatelessWidget {
  const _ParameterTable({
    required this.parameters,
    this.accent = AppColors.primary,
  });

  final List<Parameter> parameters;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children:
            parameters.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              final isAlt = idx % 2 == 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isAlt
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.transparent,
                  border:
                      idx < parameters.length - 1
                          ? const Border(
                            bottom: BorderSide(
                              color: AppColors.surfaceHigh,
                              width: 0.5,
                            ),
                          )
                          : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 55,
                      child: Text(
                        p.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      p.formattedAmount,
                      style: TextStyle(
                        color: accent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.unit,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

// ── Steps List ────────────────────────────────────────────────────────────────

class _StepsList extends StatelessWidget {
  const _StepsList({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children:
            steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          step,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
