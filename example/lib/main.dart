import 'package:flutter/material.dart';
import 'package:privacy_screen_guard/privacy_screen_guard.dart';

void main() => runApp(const GuardExample());

class GuardExample extends StatefulWidget {
  const GuardExample({super.key});

  @override
  State<GuardExample> createState() => _GuardExampleState();
}

class _GuardExampleState extends State<GuardExample> {
  final guard = PrivacyScreenGuard.instance;
  bool enabled = false;

  Future<void> toggle() async {
    enabled ? await guard.disable() : await guard.enable();
    setState(() => enabled = !enabled);
  }

  Future<void> simulateExternalFlow() async {
    await guard.runUnprotected(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Privacy Screen Guard')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: toggle,
                child: Text(enabled ? '关闭保护' : '开启保护'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: simulateExternalFlow,
                child: const Text('模拟 URL / 购买放行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
