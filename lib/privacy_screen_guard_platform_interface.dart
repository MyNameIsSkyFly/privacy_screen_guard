import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'privacy_screen_guard_method_channel.dart';

abstract class PrivacyScreenGuardPlatform extends PlatformInterface {
  /// Constructs a PrivacyScreenGuardPlatform.
  PrivacyScreenGuardPlatform() : super(token: _token);

  static final Object _token = Object();

  static PrivacyScreenGuardPlatform _instance =
      MethodChannelPrivacyScreenGuard();

  /// The default instance of [PrivacyScreenGuardPlatform] to use.
  ///
  /// Defaults to [MethodChannelPrivacyScreenGuard].
  static PrivacyScreenGuardPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PrivacyScreenGuardPlatform] when
  /// they register themselves.
  static set instance(PrivacyScreenGuardPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> enable();
  Future<void> disable();
  Future<void> pause();
  Future<void> resume();
  Future<bool> isEnabled();
}
