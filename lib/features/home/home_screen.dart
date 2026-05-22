import 'package:flutter/material.dart';

import '../../core/firestore/category_repository.dart';
import '../../core/firestore/favorites_repository.dart';
import '../../core/firestore/item_repository.dart';
import '../../core/firestore/mock_catalog_repository.dart';
import '../../core/models/category.dart';
import '../../core/models/content_item.dart';
import '../../core/models/member.dart';
import '../../core/search/content_search.dart';
import '../../features/item_detail/item_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/content_chips.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({
    this.categoryRepository = const MockCategoryRepository(),
    this.itemRepository = const MockItemRepository(),
    FavoritesRepository? favoritesRepository,
    this.member = DemoAccounts.admin,
    super.key,
  }) : favoritesRepository =
           favoritesRepository ??
           InMemoryFavoritesRepository(initialFavorites: {'classic_milk_tea'});

  final CategoryRepository categoryRepository;
  final ItemRepository itemRepository;
  final FavoritesRepository favoritesRepository;
  final Member member;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<_HomeCatalog> _catalogFuture = _loadCatalog();
  final TextEditingController _searchController = TextEditingController();
  Set<String> _favoriteIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Menu',
            onPressed: () {},
            icon: const Icon(Icons.menu),
          ),
          title: const Text('ZinmeAPP'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Search',
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Lock',
              onPressed: () {},
              icon: const Icon(Icons.lock_outline),
            ),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'All'),
              Tab(text: 'Recipes'),
              Tab(text: 'SOPs'),
              Tab(text: 'Favorites'),
            ],
          ),
        ),
        floatingActionButton: widget.member.isAdmin
            ? FloatingActionButton.extended(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              )
            : null,
        body: FutureBuilder<_HomeCatalog>(
          future: _catalogFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final catalog = snapshot.requireData;
            final categoriesById = catalog.categoriesById;

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search recipes, SOPs, ingredients, or steps',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _HomeSummary(
                  itemCount: catalog.items.length,
                  draftCount: catalog.items
                      .where((item) => item.status == ContentStatus.draft)
                      .length,
                  favoriteCount: _favoriteIds.length,
                ),
                Expanded(
                  child: TabBarView(
                    children: <Widget>[
                      _ContentList(
                        items: _itemsForTab(catalog, _HomeTab.all),
                        categoriesById: categoriesById,
                        favoriteIds: _favoriteIds,
                        member: widget.member,
                        onToggleFavorite: _toggleFavorite,
                      ),
                      _ContentList(
                        items: _itemsForTab(catalog, _HomeTab.recipes),
                        categoriesById: categoriesById,
                        favoriteIds: _favoriteIds,
                        member: widget.member,
                        onToggleFavorite: _toggleFavorite,
                      ),
                      _ContentList(
                        items: _itemsForTab(catalog, _HomeTab.sops),
                        categoriesById: categoriesById,
                        favoriteIds: _favoriteIds,
                        member: widget.member,
                        onToggleFavorite: _toggleFavorite,
                      ),
                      _ContentList(
                        items: _itemsForTab(catalog, _HomeTab.favorites),
                        categoriesById: categoriesById,
                        favoriteIds: _favoriteIds,
                        member: widget.member,
                        onToggleFavorite: _toggleFavorite,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<_HomeCatalog> _loadCatalog() async {
    final categories = await widget.categoryRepository.listCategories();
    final items = await widget.itemRepository.listVisibleItems(widget.member);
    _favoriteIds = await widget.favoritesRepository.loadFavoriteIds(
      widget.member.uid,
    );

    return _HomeCatalog(categories: categories, items: items);
  }

  List<ContentItem> _itemsForTab(_HomeCatalog catalog, _HomeTab tab) {
    final query = _searchController.text;
    final visibleItems = switch (tab) {
      _HomeTab.all => catalog.items,
      _HomeTab.recipes => catalog.items.where((item) => item.isRecipe).toList(),
      _HomeTab.sops => catalog.items.where((item) => item.isSop).toList(),
      _HomeTab.favorites =>
        catalog.items.where((item) => _favoriteIds.contains(item.id)).toList(),
    };

    return searchContentItems(
      items: visibleItems,
      categoriesById: catalog.categoriesById,
      query: query,
    );
  }

  void _toggleFavorite(String itemId, bool isFavorite) {
    setState(() {
      if (isFavorite) {
        _favoriteIds.add(itemId);
      } else {
        _favoriteIds.remove(itemId);
      }
    });

    widget.favoritesRepository.saveFavoriteIds(widget.member.uid, _favoriteIds);
  }
}

enum _HomeTab { all, recipes, sops, favorites }

class _HomeCatalog {
  const _HomeCatalog({required this.categories, required this.items});

  final List<Category> categories;
  final List<ContentItem> items;

  Map<String, Category> get categoriesById {
    return <String, Category>{
      for (final category in categories) category.id: category,
    };
  }
}

class _HomeSummary extends StatelessWidget {
  const _HomeSummary({
    required this.itemCount,
    required this.draftCount,
    required this.favoriteCount,
  });

  final int itemCount;
  final int draftCount;
  final int favoriteCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: <Widget>[
          _Metric(label: 'Items', value: itemCount.toString()),
          _Metric(label: 'Drafts', value: draftCount.toString()),
          _Metric(label: 'Favorites', value: favoriteCount.toString()),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentList extends StatelessWidget {
  const _ContentList({
    required this.items,
    required this.categoriesById,
    required this.favoriteIds,
    required this.member,
    required this.onToggleFavorite,
  });

  final List<ContentItem> items;
  final Map<String, Category> categoriesById;
  final Set<String> favoriteIds;
  final Member member;
  final void Function(String itemId, bool isFavorite) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No matching content.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemBuilder: (context, index) {
        final item = items[index];
        final category = categoriesById[item.categoryId];
        final isFavorite = favoriteIds.contains(item.id);

        return _ContentCard(
          item: item,
          category: category,
          isFavorite: isFavorite,
          member: member,
          onToggleFavorite: onToggleFavorite,
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.item,
    required this.category,
    required this.isFavorite,
    required this.member,
    required this.onToggleFavorite,
  });

  final ContentItem item;
  final Category? category;
  final bool isFavorite;
  final Member member;
  final void Function(String itemId, bool isFavorite) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => ItemDetailScreen(
              item: item,
              category: category,
              isFavorite: isFavorite,
              onFavoriteChanged: (value) => onToggleFavorite(item.id, value),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  ContentTypeChip(item: item),
                  const SizedBox(width: 8),
                  if (member.isAdmin) StatusChip(status: item.status),
                  const Spacer(),
                  IconButton(
                    tooltip: isFavorite ? 'Remove favorite' : 'Add favorite',
                    onPressed: () => onToggleFavorite(item.id, !isFavorite),
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? AppColors.favorite : null,
                    ),
                  ),
                  if (member.isAdmin)
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                category?.name ?? 'Uncategorized',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.gold),
              ),
              const SizedBox(height: 10),
              Text(item.previewText),
              if (item.previewParameters.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.previewParameters.take(3).map((parameter) {
                    return Chip(
                      label: Text(
                        '${parameter.name}: ${parameter.formattedAmount} ${parameter.unit}',
                      ),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
