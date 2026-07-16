import 'storage_interface.dart';

final Map<String, String> _memoryStorage = <String, String>{};

AppStorage createStorage() => _MemoryStorage();

class _MemoryStorage implements AppStorage {
  @override
  Future<String?> read(String key) async => _memoryStorage[key];

  @override
  Future<void> write(String key, String value) async {
    _memoryStorage[key] = value;
  }
}
