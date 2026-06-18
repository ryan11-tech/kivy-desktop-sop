import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/attendance/attendance_controller.dart';
import '../../core/attendance/attendance_repository.dart';
import '../../core/attendance/location_service.dart';
import '../../core/booking/booking_controller.dart';
import '../../core/booking/booking_models.dart';
import '../../core/booking/booking_repository.dart';
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
import '../attendance/attendance_history_screen.dart';
import '../category/category_screen.dart';
import '../item_detail/item_detail_screen.dart';
import '../schedule/alerts_screen.dart';
import '../schedule/schedule_screen.dart';
import '../settings/settings_screen.dart';
import 'attendance_card.dart';

/// Which content kind the home body is showing.
enum HomeSegment { sop, recipe }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.favoritesRepository,
    // Real admin/staff state comes from the session. This fallback keeps tests
    // and preview harnesses in staff mode unless they pass an explicit member.
    this.member = DemoAccounts.staff,
    this.onLock,
    super.key,
  });

  final FavoritesRepository favoritesRepository;
  final Member member;
  final VoidCallback? onLock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  SopCatalogController? _catalog;
  RecipeCatalogController? _recipeCatalog;
  AttendanceController? _attendance;
  BookingController? _booking;
  StaffSessionController? _session;
  Set<String> _favoriteIds = {};
  String? _favoriteScopeKey;
  int _navIndex = 0;
  HomeSegment _segment = HomeSegment.sop;
  bool _showSearch = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _catalog ??= SopCatalogController(context.read<SopRepository>())
      ..addListener(_onCatalogChanged);
    _recipeCatalog ??= RecipeCatalogController(context.read<RecipeRepository>())
      ..addListener(_onCatalogChanged);
    _attendance ??= AttendanceController(
      context.read<AttendanceRepository>(),
      context.read<LocationProvider>(),
    )..addListener(_onCatalogChanged);
    _booking ??= BookingController(context.read<BookingRepository>())
      ..addListener(_onCatalogChanged);

    final session = context.read<StaffSessionController>();
    if (!identical(session, _session)) {
      _session?.removeListener(_onSessionChanged);
      _session = session..addListener(_onSessionChanged);
    }

    _syncShop();
    _syncFavorites();
  }

  void _onSessionChanged() {
    _syncShop();
    _syncFavorites();
  }

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
    _attendance?.loadForShop(shop);
    _booking?.loadForShop(shop);
  }

  void _syncFavorites() {
    final scopeKey = _currentFavoriteScopeKey;
    if (scopeKey == _favoriteScopeKey) return;
    _favoriteScopeKey = scopeKey;
    widget.favoritesRepository.loadFavoriteIds(_favoritesUserId).then((ids) {
      if (!mounted || _favoriteScopeKey != scopeKey) return;
      setState(() => _favoriteIds = {...ids});
    });
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    _catalog?.removeListener(_onCatalogChanged);
    _catalog?.dispose();
    _recipeCatalog?.removeListener(_onCatalogChanged);
    _recipeCatalog?.dispose();
    _attendance?.removeListener(_onCatalogChanged);
    _attendance?.dispose();
    _booking?.removeListener(_onCatalogChanged);
    _booking?.dispose();
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
              ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : _buildSelectedPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar() {
    final member = _effectiveMember;
    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: _openDrawer,
      ),
      title:
          _showSearch && _isCatalogTab
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
                    _titleForActiveTab(),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
      actions: [
        if (_isCatalogTab) ...[
          IconButton(
            tooltip:
                _segment == HomeSegment.sop
                    ? 'Refresh SOPs'
                    : 'Refresh recipes',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _currentCatalogIsLoading ? null : _refreshCurrentCatalog,
          ),
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
        ],
        if (_navIndex == 2 && _booking != null) _buildAlertsBell(),
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            member.isAdmin ? 'ADMIN' : 'STAFF',
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

  bool get _currentCatalogIsLoading {
    if (!_isCatalogTab) return false;
    final status =
        _segment == HomeSegment.sop ? _catalog?.status : _recipeCatalog?.status;
    return status == SopCatalogStatus.loading;
  }

  bool get _isCatalogTab => _navIndex == 0 || _navIndex == 1;

  String get _favoritesUserId => _session?.state.user?.id ?? widget.member.uid;

  Member get _effectiveMember =>
      _session?.state.user?.isAdmin == true
          ? DemoAccounts.admin
          : widget.member;

  String get _currentFavoriteScopeKey {
    final shopId = _session?.state.activeShop?.id ?? 'no-shop';
    return '$_favoritesUserId::$shopId';
  }

  String _titleForActiveTab() {
    return switch (_navIndex) {
      1 => 'Favorites',
      2 => 'Staff Schedule',
      3 => 'Settings',
      _ => _segment == HomeSegment.sop ? 'Food & Beverage SOP' : 'Recipes',
    };
  }

  Widget _buildSelectedPage() {
    final member = _effectiveMember;
    if (_navIndex == 2) {
      return ScheduleScreen(controller: _booking!);
    }
    if (_navIndex == 3) {
      return SettingsScreen(isAdmin: member.isAdmin, embedded: true);
    }
    return Column(
      children: [
        if (_attendance != null)
          AttendanceCard(
            controller: _attendance!,
            onViewHistory: _openAttendanceHistory,
            nextShift: _nextShift,
            todayShiftStart: _todayShiftStart,
          ),
        _buildSegmentBar(),
        Expanded(child: _buildRefreshableBody()),
      ],
    );
  }

  void _openAttendanceHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AttendanceHistoryScreen()),
    );
  }

  // Bookings at the ACTIVE shop only — the attendance card is shop-scoped, so a
  // next-shift / lateness note must not be computed from another shop's booking.
  List<MyBooking> get _activeShopBookings {
    final shopId = _session?.state.activeShop?.id;
    if (shopId == null) return const <MyBooking>[];
    return (_booking?.bookings ?? const <MyBooking>[])
        .where((booking) => booking.shopId == shopId)
        .toList(growable: false);
  }

  // Nearest upcoming booked shift at the active shop (bookings are sorted
  // soonest-first), for the card's "next shift" tie-in. Null when none upcoming
  // or the booking time fails to parse.
  MyBooking? get _nextShift {
    final nowUtc = DateTime.now().toUtc();
    for (final booking in _activeShopBookings) {
      final start = booking.startInstant;
      if (start != null && start.isAfter(nowUtc)) return booking;
    }
    return null;
  }

  // Start (UTC instant) of the active-shop shift currently in progress — the one
  // whose [start, end) window contains now — used to flag a late clock-in. Null
  // when no shift is in progress.
  DateTime? get _todayShiftStart {
    final nowUtc = DateTime.now().toUtc();
    for (final booking in _activeShopBookings) {
      final start = booking.startInstant;
      final end = booking.endInstant;
      if (start != null &&
          end != null &&
          !start.isAfter(nowUtc) &&
          end.isAfter(nowUtc)) {
        return start;
      }
    }
    return null;
  }

  // Schedule-change alerts bell with an unread badge (T066).
  Widget _buildAlertsBell() {
    final unread = _booking?.unreadAlertCount ?? 0;
    return IconButton(
      tooltip: 'Schedule alerts',
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined, color: Colors.white),
      ),
      onPressed: () {
        final booking = _booking;
        if (booking == null) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AlertsScreen(controller: booking),
          ),
        );
      },
    );
  }

  Widget _buildRefreshableBody() {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _refreshCurrentCatalog,
      child: _buildBody(),
    );
  }

  Future<void> _refreshCurrentCatalog() async {
    final shop = _session?.state.activeShop;
    if (shop == null) {
      _syncShop();
      return;
    }

    if (_segment == HomeSegment.sop) {
      await _catalog?.loadForShop(shop, force: true);
    } else {
      await _recipeCatalog?.loadForShop(shop, force: true);
    }
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
        return Center(
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
    final member = _effectiveMember;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
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
          member: member,
          onToggleFavorite: _toggleFavorite,
          onOpenCategory:
              () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder:
                      (_) => CategoryScreen(
                        category: category,
                        items: group.items,
                        member: member,
                        favoriteIds: _favoriteIds,
                        onToggleFavorite: _toggleFavorite,
                      ),
                ),
              ),
        );
      },
    );
  }

  Widget _buildFavoritesView(List<SopGroup> groups) {
    final member = _effectiveMember;
    final favItems =
        _flatItems(groups).where((i) => _favoriteIds.contains(i.id)).toList();

    if (favItems.isEmpty) {
      return const _MessageView(
        icon: Icons.star_border,
        title: 'No favorites yet',
        message: 'Tap the star on any SOP or recipe to save it.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      itemCount: favItems.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = favItems[index];
        return _ItemRow(
          item: item,
          category: null,
          isFavorite: true,
          member: member,
          onToggleFavorite: _toggleFavorite,
        );
      },
    );
  }

  Widget _buildSearchResults(List<SopGroup> groups, String query) {
    final member = _effectiveMember;
    final results = searchContentItems(
      items: _flatItems(groups),
      categoriesById: const <String, Category>{},
      query: query,
    );

    if (results.isEmpty) {
      return const _MessageView(
        icon: Icons.search_off,
        title: 'No results found',
        message: 'Try another name, ingredient, or step.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = results[index];
        return _ItemRow(
          item: item,
          category: null,
          isFavorite: _favoriteIds.contains(item.id),
          member: member,
          onToggleFavorite: _toggleFavorite,
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.primary, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _navIndex,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _navIndex = index),
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
    final member = _effectiveMember;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => _DrawerMenu(
            member: member,
            onHome: () => _selectMainTab(0),
            onFavorites: () => _selectMainTab(1),
            onSchedule: () => _selectMainTab(2),
            onSettings: () => _selectMainTab(3),
            onLock: widget.onLock == null ? null : _lockApp,
            onSignOut: _signOut,
          ),
    );
  }

  void _selectMainTab(int index) {
    Navigator.of(context).pop();
    setState(() => _navIndex = index);
  }

  void _lockApp() {
    Navigator.of(context).pop();
    widget.onLock?.call();
  }

  Future<void> _signOut() async {
    Navigator.of(context).pop();
    await context.read<StaffSessionController>().signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
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
    widget.favoritesRepository.saveFavoriteIds(_favoritesUserId, _favoriteIds);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
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
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
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
            ),
          ),
        );
      },
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
  });

  final Category category;
  final List<ContentItem> items;
  final String unitLabel;
  final Set<String> favoriteIds;
  final Member member;
  final void Function(String, bool) onToggleFavorite;
  final VoidCallback onOpenCategory;

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
                    child: Icon(Icons.chevron_right, color: AppColors.primary),
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
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

// ── Drawer Menu ───────────────────────────────────────────────────────────────

class _DrawerMenu extends StatelessWidget {
  const _DrawerMenu({
    required this.member,
    required this.onHome,
    required this.onFavorites,
    required this.onSchedule,
    required this.onSettings,
    required this.onSignOut,
    this.onLock,
  });

  final Member member;
  final VoidCallback onHome;
  final VoidCallback onFavorites;
  final VoidCallback onSchedule;
  final VoidCallback onSettings;
  final VoidCallback? onLock;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
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
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.surfaceHigh),
              _DrawerItem(icon: Icons.home, label: 'Home', onTap: onHome),
              _DrawerItem(
                icon: Icons.star,
                label: 'Favorites',
                onTap: onFavorites,
              ),
              _DrawerItem(
                icon: Icons.schedule,
                label: 'Schedule',
                onTap: onSchedule,
              ),
              _DrawerItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: onSettings,
              ),
              if (onLock != null)
                _DrawerItem(
                  icon: Icons.lock_outline,
                  label: 'Lock',
                  onTap: onLock!,
                ),
              const Divider(color: AppColors.surfaceHigh),
              _DrawerItem(
                icon: Icons.logout,
                label: 'Sign out',
                onTap: () => onSignOut(),
              ),
            ],
          ),
        ),
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
