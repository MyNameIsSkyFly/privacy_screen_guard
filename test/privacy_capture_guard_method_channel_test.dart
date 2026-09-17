import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_capture_guard/privacy_capture_guard_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelPrivacyCaptureGuard platform;
  const MethodChannel channel = MethodChannel('privacy_capture_guard');
  final calls = <String>[];

  setUp(() {
    platform = MethodChannelPrivacyCaptureGuard();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          calls.add(methodCall.method);
          return methodCall.method == 'isEnabled' ? true : null;
        });
  });

  tearDown(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('forwards protection operations to the native plugin', () async {
    await platform.enable();
    await platform.pause();
    await platform.resume();
    expect(await platform.isEnabled(), true);
    await platform.disable();

    expect(calls, ['enable', 'pause', 'resume', 'isEnabled', 'disable']);
  });
}
