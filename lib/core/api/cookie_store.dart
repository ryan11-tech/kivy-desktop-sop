import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// Builds a persistent cookie jar rooted under the app documents directory.
///
/// We persist Better Auth's session cookie across launches so the bootstrap
/// flow can call `/api/staff/me` without prompting for credentials.
class CookieStore {
  CookieStore({this.subdirectory = '.cookies'});

  final String subdirectory;

  PersistCookieJar? _jar;

  Future<PersistCookieJar> jar() async {
    final cached = _jar;
    if (cached != null) {
      return cached;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$subdirectory');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final created = PersistCookieJar(
      storage: FileStorage(dir.path),
      ignoreExpires: false,
    );
    _jar = created;
    return created;
  }

  Future<void> clear() async {
    final j = await jar();
    await j.deleteAll();
  }
}
