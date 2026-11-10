import 'local_storage_io.dart'
    if (dart.library.js_interop) 'local_storage_web.dart';

class LocalStorage {
  static String? readSettingsJson() => LocalStorageImpl.readRaw();
  static void writeSettingsJson(String json) => LocalStorageImpl.writeRaw(json);
}

