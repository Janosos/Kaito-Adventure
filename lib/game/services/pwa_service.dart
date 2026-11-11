import 'pwa_service_stub.dart'
    if (dart.library.html) 'pwa_service_web.dart';

abstract class PwaService {
  static PwaService get instance => getPwaService();

  bool get isWeb;
  bool get isIos;
  bool get isAndroid;
  bool get isAlreadyInstalled;
  bool get canPromptInstall;

  Future<bool> promptInstall();
  void requestFullscreenLandscape();
}
