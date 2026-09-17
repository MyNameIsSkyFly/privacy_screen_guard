import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_capture_guard/privacy_capture_guard.dart';
import 'package:privacy_capture_guard/privacy_capture_guard_platform_interface.dart';
import 'package:privacy_capture_guard/privacy_capture_guard_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPrivacyCaptureGuardPlatform
    with MockPlatformInterfaceMixin
    implements PrivacyCaptureGuardPlatform {
  bool enabled = false;
  int pauseDepth = 0;
  @override
  Future<void> enable() async => enabled = true;
  @override
  Future<void> disable() async => enabled = false;
  @override
  Future<bool> isEnabled() async => enabled;
  @override
  Future<void> pause() async => pauseDepth++;
  @override
  Future<void> resume() async => pauseDepth--;
}

void main() {
  final PrivacyCaptureGuardPlatform initialPlatform =
      PrivacyCaptureGuardPlatform.instance;

  test('$MethodChannelPrivacyCaptureGuard is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPrivacyCaptureGuard>());
  });

  test('runUnprotected restores after an error', () async {
    final fakePlatform = MockPrivacyCaptureGuardPlatform()..enabled = true;
    PrivacyCaptureGuardPlatform.instance = fakePlatform;
    await expectLater(
      PrivacyCaptureGuard.instance.runUnprotected<void>(
        () async => throw StateError('failed'),
        restoreDelay: Duration.zero,
      ),
      throwsStateError,
    );
    expect(fakePlatform.pauseDepth, 0);
    expect(fakePlatform.enabled, true);
  });
}
