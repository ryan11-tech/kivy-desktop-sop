import 'package:flutter/foundation.dart';

import '../api/api_exceptions.dart';
import '../sops/sop_catalog_controller.dart' show SopCatalogStatus;
import '../sops/sop_category_mapper.dart' show SopGroup;
import '../staff/shop.dart';
import 'recipe_category_mapper.dart';
import 'recipe_repository.dart';

/// Loads and exposes the recipe catalog for the currently selected shop.
///
/// Mirrors [SopCatalogController] (reusing its [SopCatalogStatus] and the
/// shared [SopGroup] struct) so the home screen can render either catalog
/// through one code path. Reloads when the active shop id changes and clears
/// the previous shop's data first, so a slow response cannot leak across shops.
class RecipeCatalogController extends ChangeNotifier {
  RecipeCatalogController(this._repository);

  final RecipeRepository _repository;

  SopCatalogStatus _status = SopCatalogStatus.noShopSelected;
  SopCatalogStatus get status => _status;

  List<SopGroup> _groups = const <SopGroup>[];
  List<SopGroup> get groups => _groups;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _loadedShopId;
  int _requestToken = 0;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Loads recipes for [shop]. No-op when the shop is unchanged and the last
  /// load succeeded, unless [force] is set.
  Future<void> loadForShop(Shop? shop, {bool force = false}) async {
    if (shop == null) {
      _loadedShopId = null;
      _groups = const <SopGroup>[];
      _errorMessage = null;
      _setStatus(SopCatalogStatus.noShopSelected);
      return;
    }

    final settled =
        _status == SopCatalogStatus.loaded || _status == SopCatalogStatus.empty;
    final inFlight =
        _status == SopCatalogStatus.loading && shop.id == _loadedShopId;
    if (!force && shop.id == _loadedShopId && (settled || inFlight)) {
      return;
    }

    await _load(shop.id);
  }

  /// Retries the current shop after an error.
  Future<void> retry() async {
    final shopId = _loadedShopId;
    if (shopId != null) {
      await _load(shopId);
    }
  }

  Future<void> _load(String shopId) async {
    final token = ++_requestToken;
    _loadedShopId = shopId;
    // Clear the previous shop's groups up front so a switch never shows stale data.
    _groups = const <SopGroup>[];
    _errorMessage = null;
    _setStatus(SopCatalogStatus.loading);

    try {
      final items = await _repository.listShopRecipes(shopId);
      if (_isStale(token)) return;
      _groups = groupByRecipeType(items);
      _setStatus(
        _groups.isEmpty ? SopCatalogStatus.empty : SopCatalogStatus.loaded,
      );
    } on UnauthorizedException catch (error) {
      if (_isStale(token)) return;
      _fail(SopCatalogStatus.permissionDenied, error.message);
    } on ClientApiException catch (error) {
      if (_isStale(token)) return;
      final denied = error.statusCode == 403;
      _fail(
        denied ? SopCatalogStatus.permissionDenied : SopCatalogStatus.error,
        error.message,
      );
    } on ApiException catch (error) {
      if (_isStale(token)) return;
      _fail(SopCatalogStatus.error, error.message);
    } catch (_) {
      if (_isStale(token)) return;
      _fail(SopCatalogStatus.error, 'Something went wrong. Please try again.');
    }
  }

  bool _isStale(int token) => _disposed || token != _requestToken;

  void _fail(SopCatalogStatus status, String message) {
    _errorMessage = message;
    _setStatus(status);
  }

  void _setStatus(SopCatalogStatus status) {
    _status = status;
    if (!_disposed) {
      notifyListeners();
    }
  }
}
