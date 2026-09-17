import 'privacy_capture_guard_platform_interface.dart';

/// Prevents Android screenshots and obscures iOS screen recordings.
class PrivacyCaptureGuard {
  PrivacyCaptureGuard._();

  static final PrivacyCaptureGuard instance = PrivacyCaptureGuard._();

  Future<void> enable() => PrivacyCaptureGuardPlatform.instance.enable();
  Future<void> disable() => PrivacyCaptureGuardPlatform.instance.disable();
  Future<bool> get isEnabled => PrivacyCaptureGuardPlatform.instance.isEnabled();

  /// Begins a manually managed temporary bypass. Calls may be nested.
  Future<void> pause() => PrivacyCaptureGuardPlatform.instance.pause();

  /// Ends one [pause] scope and restores protection when the last scope ends.
  Future<void> resume() => PrivacyCaptureGuardPlatform.instance.resume();

  /// Temporarily allows capture while an external system UI is presented.
  ///
  /// Use around `launchUrl`, StoreKit/Play Billing calls, and similar flows.
  /// Calls may be nested safely.
  Future<T> runUnprotected<T>(
    Future<T> Function() action, {
    Duration restoreDelay = const Duration(milliseconds: 350),
  }) async {
    await PrivacyCaptureGuardPlatform.instance.pause();
    await Future<void>.delayed(Duration.zero);
    try {
      return await action();
    } finally {
      if (restoreDelay > Duration.zero) {
        await Future<void>.delayed(restoreDelay);
      }
      await PrivacyCaptureGuardPlatform.instance.resume();
    }
  }
}
