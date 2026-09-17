import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'privacy_capture_guard_method_channel.dart';

abstract class PrivacyCaptureGuardPlatform extends PlatformInterface {
  /// Constructs a PrivacyCaptureGuardPlatform.
  PrivacyCaptureGuardPlatform() : super(token: _token);

  static final Object _token = Object();

  static PrivacyCaptureGuardPlatform _instance =
      MethodChannelPrivacyCaptureGuard();

  /// The default instance of [PrivacyCaptureGuardPlatform] to use.
  ///
  /// Defaults to [MethodChannelPrivacyCaptureGuard].
  static PrivacyCaptureGuardPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PrivacyCaptureGuardPlatform] when
  /// they register themselves.
  static set instance(PrivacyCaptureGuardPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> enable();
  Future<void> disable();
  Future<void> pause();
  Future<void> resume();
  Future<bool> isEnabled();
}
