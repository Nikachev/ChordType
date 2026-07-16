import 'storage_factory_stub.dart'
    if (dart.library.html) 'storage_factory_web.dart' as implementation;
import 'storage_interface.dart';

export 'storage_interface.dart';

AppStorage createAppStorage() => implementation.createStorage();
