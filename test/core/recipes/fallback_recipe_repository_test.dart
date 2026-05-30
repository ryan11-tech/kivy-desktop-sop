import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/recipes/fallback_recipe_repository.dart';
import 'package:zinme_app/core/recipes/recipe_repository.dart';

class _ThrowingRepo implements RecipeRepository {
  _ThrowingRepo(this.error);

  final Object error;

  @override
  Future<List<ContentItem>> listShopRecipes(String shopId) async => throw error;
}

class _EmptyRepo implements RecipeRepository {
  @override
  Future<List<ContentItem>> listShopRecipes(String shopId) async =>
      const <ContentItem>[];
}

void main() {
  test(
    'network failure with useMock returns published mock recipes only',
    () async {
      final repo = FallbackRecipeRepository(
        _ThrowingRepo(const NetworkException('offline')),
        useMock: true,
      );

      final items = await repo.listShopRecipes('shop-1');

      expect(items, isNotEmpty);
      expect(items.every((item) => item.isRecipe && item.isPublished), isTrue);
    },
  );

  test('network failure without useMock rethrows', () async {
    final repo = FallbackRecipeRepository(
      _ThrowingRepo(const NetworkException('offline')),
      useMock: false,
    );

    expect(
      () => repo.listShopRecipes('shop-1'),
      throwsA(isA<NetworkException>()),
    );
  });

  test('never falls back on auth, permission, or server errors', () async {
    final errors = <ApiException>[
      const UnauthorizedException('unauthorized'),
      const ClientApiException('forbidden', statusCode: 403),
      const ServerApiException('boom', statusCode: 500),
    ];

    for (final error in errors) {
      final repo = FallbackRecipeRepository(_ThrowingRepo(error), useMock: true);
      await expectLater(
        () => repo.listShopRecipes('shop-1'),
        throwsA(isA<ApiException>()),
      );
    }
  });

  test('passes remote success through untouched', () async {
    final repo = FallbackRecipeRepository(_EmptyRepo(), useMock: true);

    expect(await repo.listShopRecipes('shop-1'), isEmpty);
  });
}
