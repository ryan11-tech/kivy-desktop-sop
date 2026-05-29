import 'package:flutter_test/flutter_test.dart';
import 'package:zinme_app/core/api/api_exceptions.dart';
import 'package:zinme_app/core/models/content_item.dart';
import 'package:zinme_app/core/sops/fallback_sop_repository.dart';
import 'package:zinme_app/core/sops/sop_repository.dart';

class _ThrowingRepo implements SopRepository {
  _ThrowingRepo(this.error);

  final Object error;

  @override
  Future<List<ContentItem>> listShopSops(String shopId) async => throw error;
}

class _EmptyRepo implements SopRepository {
  @override
  Future<List<ContentItem>> listShopSops(String shopId) async =>
      const <ContentItem>[];
}

void main() {
  test(
    'network failure with useMock returns published mock SOPs only',
    () async {
      final repo = FallbackSopRepository(
        _ThrowingRepo(const NetworkException('offline')),
        useMock: true,
      );

      final items = await repo.listShopSops('shop-1');

      expect(items, isNotEmpty);
      expect(items.every((item) => item.isSop && item.isPublished), isTrue);
    },
  );

  test('network failure without useMock rethrows', () async {
    final repo = FallbackSopRepository(
      _ThrowingRepo(const NetworkException('offline')),
      useMock: false,
    );

    expect(() => repo.listShopSops('shop-1'), throwsA(isA<NetworkException>()));
  });

  test('never falls back on auth, permission, or server errors', () async {
    final errors = <ApiException>[
      const UnauthorizedException('unauthorized'),
      const ClientApiException('forbidden', statusCode: 403),
      const ServerApiException('boom', statusCode: 500),
    ];

    for (final error in errors) {
      final repo = FallbackSopRepository(_ThrowingRepo(error), useMock: true);
      await expectLater(
        () => repo.listShopSops('shop-1'),
        throwsA(isA<ApiException>()),
      );
    }
  });

  test('passes remote success through untouched', () async {
    final repo = FallbackSopRepository(_EmptyRepo(), useMock: true);

    expect(await repo.listShopSops('shop-1'), isEmpty);
  });
}
