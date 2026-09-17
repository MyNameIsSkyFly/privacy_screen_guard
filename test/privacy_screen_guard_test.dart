import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_screen_guard/privacy_screen_guard.dart';
import 'package:privacy_screen_guard/privacy_screen_guard_platform_interface.dart';
import 'package:privacy_screen_guard/privacy_screen_guard_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPrivacyScreenGuardPlatform
    with MockPlatformInterfaceMixin
    implements PrivacyScreenGuardPlatform {
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
  final PrivacyScreenGuardPlatform initialPlatform =
      PrivacyScreenGuardPlatform.instance;

  test('$MethodChannelPrivacyScreenGuard is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPrivacyScreenGuard>());
  });

  test('runUnprotected restores after an error', () async {
    final fakePlatform = MockPrivacyScreenGuardPlatform()..enabled = true;
    PrivacyScreenGuardPlatform.instance = fakePlatform;
    await expectLater(
      PrivacyScreenGuard.instance.runUnprotected<void>(
        () async => throw StateError('failed'),
        restoreDelay: Duration.zero,
      ),
      throwsStateError,
    );
    expect(fakePlatform.pauseDepth, 0);
    expect(fakePlatform.enabled, true);
  });
}
