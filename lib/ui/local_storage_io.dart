import 'dart:io';

class LocalStorageImpl {
  static File _resolveSettingsFile() {
    try {
      if (Platform.isWindows) {
        final appData = Platform.environment['LOCALAPPDATA'] ??
            Platform.environment['APPDATA'];
        if (appData != null && appData.isNotEmpty) {
          final dir = Directory('$appData\\KaitoAdventure');
          if (!dir.existsSync()) {
            dir.createSync(recursive: true);
          }
          return File('${dir.path}\\kaito_settings_v1.json');
        }
      }
      // On Android, Directory.systemTemp is /data/user/0/<pkg>/cache;
      // its sibling /files is the permanent internal storage directory.
      final parentDir = Directory.systemTemp.parent;
      final filesDir = Directory('${parentDir.path}/files');
      if (filesDir.existsSync()) {
        return File('${filesDir.path}/kaito_settings_v1.json');
      }
    } catch (_) {}
    return File('${Directory.systemTemp.path}/kaito_settings_v1.json');
  }

  static String? readRaw() {
    try {
      final file = _resolveSettingsFile();
      if (file.existsSync()) {
        return file.readAsStringSync();
      }
    } catch (_) {}
    return null;
  }

  static void writeRaw(String data) {
    try {
      final file = _resolveSettingsFile();
      file.writeAsStringSync(data, flush: true);
    } catch (_) {}
  }
}

