import 'privacy_screen_guard_platform_interface.dart';

/// Prevents Android screenshots and obscures iOS screen recordings.
class PrivacyScreenGuard {
  PrivacyScreenGuard._();

  static final PrivacyScreenGuard instance = PrivacyScreenGuard._();

  Future<void> enable() => PrivacyScreenGuardPlatform.instance.enable();
  Future<void> disable() => PrivacyScreenGuardPlatform.instance.disable();
  Future<bool> get isEnabled => PrivacyScreenGuardPlatform.instance.isEnabled();

  /// Begins a manually managed temporary bypass. Calls may be nested.
  Future<void> pause() => PrivacyScreenGuardPlatform.instance.pause();

  /// Ends one [pause] scope and restores protection when the last scope ends.
  Future<void> resume() => PrivacyScreenGuardPlatform.instance.resume();

  /// Temporarily allows capture while an external system UI is presented.
  ///
  /// Use around `launchUrl`, StoreKit/Play Billing calls, and similar flows.
  /// Calls may be nested safely.
  Future<T> runUnprotected<T>(
    Future<T> Function() action, {
    Duration restoreDelay = const Duration(milliseconds: 350),
  }) async {
    await PrivacyScreenGuardPlatform.instance.pause();
    await Future<void>.delayed(Duration.zero);
    try {
      return await action();
    } finally {
      if (restoreDelay > Duration.zero) {
        await Future<void>.delayed(restoreDelay);
      }
      await PrivacyScreenGuardPlatform.instance.resume();
    }
  }
}
