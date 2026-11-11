import 'pwa_service.dart';

PwaService getPwaService() => PwaServiceStub();

class PwaServiceStub extends PwaService {
  @override
  bool get isWeb => false;

  @override
  bool get isIos => false;

  @override
  bool get isAndroid => false;

  @override
  bool get isAlreadyInstalled => false;

  @override
  bool get canPromptInstall => false;

  @override
  Future<bool> promptInstall() async => false;

  @override
  void requestFullscreenLandscape() {}
}
