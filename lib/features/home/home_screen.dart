import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/firestore/favorites_repository.dart';
import '../../core/models/category.dart';
import '../../core/models/content_item.dart';
import '../../core/models/member.dart';
import '../../core/recipes/recipe_catalog_controller.dart';
import '../../core/recipes/recipe_repository.dart';
import '../../core/search/content_search.dart';
import '../../core/sops/sop_catalog_controller.dart';
import '../../core/sops/sop_category_mapper.dart';
import '../../core/sops/sop_repository.dart';
import '../../core/staff/staff_session_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/content_chips.dart';
import '../category/category_screen.dart';
import '../item_detail/item_detail_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';

/// Which content kind the home body is showing.
enum HomeSegment { sop, recipe }

class HomeScreen extends StatefulWidget {
  HomeScreen({
    FavoritesRepository? favoritesRepository,
    // Staff app is read-only — content editing lives in the portal. Default to
    // a staff identity so admin-only affordances (FAB, edit/delete) stay hidden.
    this.member = DemoAccounts.staff,
    super.key,
  }) : favoritesRepository =
           favoritesRepository ?? InMemoryFavoritesRepository();

  final FavoritesRepository favoritesRepository;
  final Member member;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  SopCatalogController? _catalog;
  RecipeCatalogController? _recipeCatalog;
  StaffSessionController? _session;
  Set<String> _favoriteIds = {};
  int _navIndex = 0;
  HomeSegment _segment = HomeSegment.sop;
  bool _showSearch = false;
  bool _favoritesRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _catalog ??= SopCatalogController(context.read<SopRepository>())
      ..addListener(_onCatalogChanged);
    _recipeCatalog ??= RecipeCatalogController(context.read<RecipeRepository>())
      ..addListener(_onCatalogChanged);

    final session = context.read<StaffSessionController>();
    if (!identical(session, _session)) {
      _session?.removeListener(_onSessionChanged);
      _session = session..addListener(_onSessionChanged);
    }

    if (!_favoritesRequested) {
      _favoritesRequested = true;
      widget.favoritesRepository.loadFavoriteIds(widget.member.uid).then((ids) {
        if (mounted) {
          setState(() => _favoriteIds = {...ids});
        }
      });
    }

    _syncShop();
  }

  void _onSessionChanged() => _syncShop();

  void _onCatalogChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _syncShop() {
    // loadForShop dedups by shop id, so calling it on every session change is
    // safe and only reloads when the active shop actually changes.
    final shop = _session?.state.activeShop;
    _catalog?.loadForShop(shop);
    _recipeCatalog?.loadForShop(shop);
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _catalog?.removeListener(_onCatalogChanged);
    _catalog?.dispose();
    _recipeCatalog?.removeListener(_onCatalogChanged);
    _recipeCatalog?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _catalog != null && _recipeCatalog != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body:
          !ready
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : Column(
                children: [
                  _buildSegmentBar(),
                  Expanded(child: _buildBody()),
                ],
              ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton:
          widget.member.isAdmin && _navIndex == 0
              ? FloatingActionButton.extended(
                onPressed: () {},
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              )
              : null,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: _openDrawer,
      ),
      title:
          _showSearch
              ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kitchen Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _navIndex == 1
                        ? 'Favorites'
                        : (_segment == HomeSegment.sop
                            ? 'Food & Beverage SOP'
                            : 'Recipes'),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
      actions: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
              }
            });
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.member.isAdmin ? 'ADMIN' : 'STAFF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: SegmentedButton<HomeSegment>(
        segments: const [
          ButtonSegment(
            value: HomeSegment.sop,
            label: Text('SOPs'),
            icon: Icon(Icons.assignment_outlined),
          ),
          ButtonSegment(
            value: HomeSegment.recipe,
            label: Text('Recipes'),
            icon: Icon(Icons.local_cafe),
          ),
        ],
        selected: {_segment},
        onSelectionChanged: (selection) {
          setState(() => _segment = selection.first);
        },
      ),
    );
  }

  Widget _buildBody() {
    final isSop = _segment == HomeSegment.sop;
    final status = isSop ? _catalog!.status : _recipeCatalog!.status;
    final groups = isSop ? _catalog!.groups : _recipeCatalog!.groups;
    final errorMessage =
        isSop ? _catalog!.errorMessage : _recipeCatalog!.errorMessage;
    final onRetry = isSop ? _catalog!.retry : _recipeCatalog!.retry;
    final noun = isSop ? 'SOPs' : 'recipes';

    switch (status) {
      case SopCatalogStatus.loading:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );
      case SopCatalogStatus.noShopSelected:
        return _MessageView(
          icon: Icons.store_mall_directory_outlined,
          title: 'No shop selected',
          message: 'Select a shop to view its $noun.',
        );
      case SopCatalogStatus.permissionDenied:
        return _MessageView(
          icon: Icons.lock_outline,
          title: 'No access',
          message:
              errorMessage ??
              'You do not have permission to view $noun for this shop.',
        );
      case SopCatalogStatus.error:
        return _MessageView(
          icon: Icons.error_outline,
          title: 'Could not load $noun',
          message: errorMessage ?? 'Something went wrong.',
          onRetry: onRetry,
        );
      case SopCatalogStatus.empty:
        return _MessageView(
          icon: Icons.inbox_outlined,
          title: 'No $noun yet',
          message: 'No published $noun are assigned to this shop.',
        );
      case SopCatalogStatus.loaded:
        break;
    }

    final query = _searchController.text.toLowerCase().trim();

    if (_navIndex == 1) {
      return _buildFavoritesView(groups);
    }

    if (query.isNotEmpty) {
      return _buildSearchResults(groups, query);
    }

    return _buildGroupList(groups);
  }

  Widget _buildGroupList(List<SopGroup> groups) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];
        final category = _categoryFor(group, index);
        return _CategoryCard(
          category: category,
          items: group.items,
          unitLabel: _segment == HomeSegment.sop ? 'SOPs' : 'recipes',
          favoriteIds: _favoriteIds,
          member: widget.member,
          onToggleFavorite: _toggleFavorite,
          onOpenCategory:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => CategoryScreen(
                        category: category,
                        items: group.items,
                        member: widget.member,
                        favoriteIds: _favoriteIds,
                        onToggleFavorite: _toggleFavorite,
                      ),
                ),
              ),
          onEdit: widget.member.isAdmin ? () {} : null,
          onDelete: widget.member.isAdmin ? () {} : null,
        );
      },
    );
  }

  Widget _buildFavoritesView(List<SopGroup> groups) {
    final favItems =
        _flatItems(groups).where((i) => _favoriteIds.contains(i.id)).toList();

    if (favItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'No favorites yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the star on any SOP to save it.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      itemCount: favItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = favItems[index];
        return _ItemRow(
          item: item,
          category: null,
          isFavorite: true,
          member: widget.member,
          onToggleFavorite: _toggleFavorite,
        );
      },
    );
  }

  Widget _buildSearchResults(List<SopGroup> groups, String query) {
    final results = searchContentItems(
      items: _flatItems(groups),
      categoriesById: const <String, Category>{},
      query: query,
    );

    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.white24),
            SizedBox(height: 12),
            Text(
              'No results found.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        return _ItemRow(
          item: item,
          category: null,
          isFavorite: _favoriteIds.contains(item.id),
          member: widget.member,
          onToggleFavorite: _toggleFavorite,
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.primary, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ScheduleScreen(isAdmin: widget.member.isAdmin),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(isAdmin: widget.member.isAdmin),
              ),
            );
          } else {
            setState(() => _navIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favorites'),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _openDrawer() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => _DrawerMenu(
            member: widget.member,
            onClose: () => Navigator.pop(context),
          ),
    );
  }

  // Synthesizes a display category from a SOP-type group so the existing
  // category card/screen can render it. Keyed by sopType, not the opaque
  // backend categoryId.
  Category _categoryFor(SopGroup group, int index) {
    return Category(id: group.key, name: group.label, icon: '', order: index);
  }

  List<ContentItem> _flatItems(List<SopGroup> groups) {
    return [for (final group in groups) ...group.items];
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

// ── State Message ─────────────────────────────────────────────────────────────

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.items,
    required this.unitLabel,
    required this.favoriteIds,
    required this.member,
    required this.onToggleFavorite,
    required this.onOpenCategory,
    this.onEdit,
    this.onDelete,
  });

  final Category category;
  final List<ContentItem> items;
  final String unitLabel;
  final Set<String> favoriteIds;
  final Member member;
  final void Function(String, bool) onToggleFavorite;
  final VoidCallback onOpenCategory;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final preview = items.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onOpenCategory,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category.icon.isNotEmpty
                          ? category.icon[0].toUpperCase()
                          : category.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${items.length} $unitLabel',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          const Divider(height: 1, color: AppColors.surfaceHigh),

          // SOP rows
          ...preview.map(
            (item) => _ItemRow(
              item: item,
              category: null,
              isFavorite: favoriteIds.contains(item.id),
              member: member,
              onToggleFavorite: onToggleFavorite,
            ),
          ),

          // View all
          if (items.length > 3)
            TextButton(
              onPressed: onOpenCategory,
              child: Text(
                'View all ${items.length} $unitLabel  >',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
          ],
        ],
      ),
    );
  }
}

// ── Item Row ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  const _ItemRow({
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
  final void Function(String, bool) onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder:
                  (_) => ItemDetailScreen(
                    item: item,
                    category: category,
                    isFavorite: isFavorite,
                    onFavoriteChanged: (val) => onToggleFavorite(item.id, val),
                  ),
            ),
          ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        child: Row(
          children: [
            Icon(
              isFavorite ? Icons.star : Icons.star_border,
              size: 16,
              color: isFavorite ? AppColors.favorite : Colors.white24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: isFavorite ? AppColors.favorite : Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
            ContentTypeChip(item: item),
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

// ── Drawer Menu ───────────────────────────────────────────────────────────────

class _DrawerMenu extends StatelessWidget {
  const _DrawerMenu({required this.member, required this.onClose});

  final Member member;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_cafe, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kitchen Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    member.isAdmin ? 'Admin Mode' : 'Staff Mode',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceHigh),
          _DrawerItem(icon: Icons.home, label: 'Home', onTap: onClose),
          _DrawerItem(icon: Icons.star, label: 'Favorites', onTap: onClose),
          _DrawerItem(icon: Icons.schedule, label: 'Schedule', onTap: onClose),
          _DrawerItem(icon: Icons.settings, label: 'Settings', onTap: onClose),
          _DrawerItem(icon: Icons.lock_outline, label: 'Lock', onTap: onClose),
          if (member.isAdmin)
            _DrawerItem(
              icon: Icons.admin_panel_settings,
              label: 'Admin Mode',
              onTap: onClose,
            ),
          const Divider(color: AppColors.surfaceHigh),
          _DrawerItem(
            icon: Icons.info_outline,
            label: 'About  v2.0',
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      dense: true,
    );
  }
}
