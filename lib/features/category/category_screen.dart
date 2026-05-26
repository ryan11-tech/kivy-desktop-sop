import 'package:flutter/material.dart';

import '../../core/firestore/favorites_repository.dart';
import '../../core/firestore/item_repository.dart';
import '../../core/firestore/mock_catalog_repository.dart';
import '../../core/models/category.dart';
import '../../core/models/content_item.dart';
import '../../core/models/member.dart';
import '../../theme/app_colors.dart';
import '../../widgets/content_chips.dart';
import '../item_detail/item_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({
    required this.category,
    required this.items,
    required this.member,
    required this.favoriteIds,
    required this.onToggleFavorite,
    super.key,
  });

  final Category category;
  final List<ContentItem> items;
  final Member member;
  final Set<String> favoriteIds;
  final void Function(String itemId, bool isFavorite) onToggleFavorite;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Set<String> _favoriteIds;

  @override
  void initState() {
    super.initState();
    _favoriteIds = Set.from(widget.favoriteIds);
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              widget.category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.items.length} recipes',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          if (widget.member.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text(
                  'Add',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body:
          widget.items.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return _RecipeCard(
                    item: item,
                    category: widget.category,
                    isFavorite: _favoriteIds.contains(item.id),
                    member: widget.member,
                    onToggleFavorite: (itemId, isFav) {
                      setState(() {
                        if (isFav) {
                          _favoriteIds.add(itemId);
                        } else {
                          _favoriteIds.remove(itemId);
                        }
                      });
                      widget.onToggleFavorite(itemId, isFav);
                    },
                    onEdit: widget.member.isAdmin ? () {} : null,
                    onDelete: widget.member.isAdmin ? () {} : null,
                  );
                },
              ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.coffee_outlined, size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            'No recipes yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap '+ Add' to add a new recipe.",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Recipe Card ───────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.item,
    required this.category,
    required this.isFavorite,
    required this.member,
    required this.onToggleFavorite,
    this.onEdit,
    this.onDelete,
  });

  final ContentItem item;
  final Category category;
  final bool isFavorite;
  final Member member;
  final void Function(String, bool) onToggleFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder:
                    (_) => ItemDetailScreen(
                      item: item,
                      category: category,
                      isFavorite: isFavorite,
                      onFavoriteChanged:
                          (val) => onToggleFavorite(item.id, val),
                    ),
              ),
            ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
              child: Row(
                children: [
                  // Type chip
                  ContentTypeChip(item: item),
                  const SizedBox(width: 8),
                  if (member.isAdmin) StatusChip(status: item.status),
                  const Spacer(),
                  // Favorite button
                  GestureDetector(
                    onTap: () => onToggleFavorite(item.id, !isFavorite),
                    child: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      size: 22,
                      color: isFavorite ? AppColors.favorite : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),

            // Name
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Preview
            if (item.previewText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.previewText,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Admin actions
            if (member.isAdmin) ...[
              const Divider(height: 1, color: AppColors.surfaceHigh),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.primary,
                      onTap: onEdit ?? () {},
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      color: Colors.red,
                      onTap: onDelete ?? () {},
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
