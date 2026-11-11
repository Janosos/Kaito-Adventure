import 'pwa_service_stub.dart'
    if (dart.library.html) 'pwa_service_web.dart';

abstract class PwaService {
  static bool forceShowInstallButtonForTest = false;
  static PwaService get instance => getPwaService();

  bool get isWeb;
  bool get isIos;
  bool get isAndroid;
  bool get isAlreadyInstalled;
  bool get canPromptInstall;

  bool get shouldShowInstallButton =>
      forceShowInstallButtonForTest || (isWeb && !isAlreadyInstalled);

  Future<bool> promptInstall();
  void requestFullscreenLandscape();
}
