import 'dart:js_interop';

@JS('window.localStorage.getItem')
external JSString? _getItem(JSString key);

@JS('window.localStorage.setItem')
external void _setItem(JSString key, JSString value);

class LocalStorageImpl {
  static const String _key = 'kaito_settings_v1';

  static String? readRaw() {
    try {
      final res = _getItem(_key.toJS);
      return res?.toDart;
    } catch (_) {
      return null;
    }
  }

  static void writeRaw(String data) {
    try {
      _setItem(_key.toJS, data.toJS);
    } catch (_) {}
  }
}

