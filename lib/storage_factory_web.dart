import 'package:web/web.dart' as web;

import 'storage_interface.dart';

AppStorage createStorage() => _WebStorage();

class _WebStorage implements AppStorage {
  @override
  Future<String?> read(String key) async =>
      web.window.localStorage.getItem(key);

  @override
  Future<void> write(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }
}
