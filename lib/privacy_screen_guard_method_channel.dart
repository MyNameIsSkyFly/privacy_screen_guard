import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'privacy_screen_guard_platform_interface.dart';

/// Method-channel bridge to this package's native implementations.
class MethodChannelPrivacyScreenGuard extends PrivacyScreenGuardPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('privacy_screen_guard');

  @override
  Future<void> enable() => methodChannel.invokeMethod<void>('enable');

  @override
  Future<void> disable() => methodChannel.invokeMethod<void>('disable');

  @override
  Future<void> pause() => methodChannel.invokeMethod<void>('pause');

  @override
  Future<void> resume() => methodChannel.invokeMethod<void>('resume');

  @override
  Future<bool> isEnabled() async =>
      await methodChannel.invokeMethod<bool>('isEnabled') ?? false;
}
