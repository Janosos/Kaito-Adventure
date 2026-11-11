import 'dart:js_interop';
import 'pwa_service.dart';

@JS('isIosDevice')
external bool _isIosDevice();

@JS('isAndroidDevice')
external bool _isAndroidDevice();

@JS('isPwaStandalone')
external bool _isPwaStandalone();

@JS('hasDeferredPwaPrompt')
external bool _hasDeferredPwaPrompt();

@JS('triggerPwaInstall')
external JSPromise<JSBoolean> _triggerPwaInstall();

@JS('requestLandscapeFullscreen')
external void _requestLandscapeFullscreen();

PwaService getPwaService() => PwaServiceWeb();

class PwaServiceWeb implements PwaService {
  @override
  bool get isWeb => true;

  @override
  bool get isIos {
    try {
      return _isIosDevice();
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isAndroid {
    try {
      return _isAndroidDevice();
    } catch (_) {
      return false;
    }
  }

  @override
  bool get isAlreadyInstalled {
    try {
      return _isPwaStandalone();
    } catch (_) {
      return false;
    }
  }

  @override
  bool get canPromptInstall {
    try {
      return _hasDeferredPwaPrompt();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> promptInstall() async {
    try {
      final jsBool = await _triggerPwaInstall().toDart;
      return jsBool.toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  void requestFullscreenLandscape() {
    try {
      _requestLandscapeFullscreen();
    } catch (_) {}
  }
}
