# privacy_capture_guard

Flutter 截屏/录屏隐私保护插件，支持 Android 和 iOS，并可在 URL 跳转、应用内购买等系统界面出现期间临时放行，避免转场黑屏。

截屏、录屏、后台快照和临时放行均由插件自身实现，不依赖 `screen_protector`。

## 平台行为

| 平台 | 截屏 | 录屏 | 后台任务快照 |
| --- | --- | --- | --- |
| Android | 系统级拦截并显示黑屏 | 系统级拦截并显示黑屏 | 隐藏 |
| iOS | 安全输入画布显示黑屏（实验性） | 安全输入画布显示黑屏 | 切后台前覆盖黑屏 |

> iOS 没有公开的“即将截屏”API。`UIApplication.userDidTakeScreenshotNotification`
> 只会在截图完成后通知，因此任何声称用公开 API 保证普通截图全黑的实现都不可靠。
> 为满足普通截图黑屏，iOS 使用插件本地实现的安全输入画布。
> 这不是苹果正式提供的截屏拦截 API，可能随 iOS 版本变化，也存在 App Store 审核风险。
> URL 和购买流程必须使用 `runUnprotected`，它会在系统界面出现前拆除安全画布。

## iOS 依赖管理

iOS 支持 Swift Package Manager 和 CocoaPods，两者使用同一份 Swift 源码。最低 iOS 版本为 13.0。

### Swift Package Manager

插件未显式限制 Flutter 最低版本，保留 Dart SDK `^3.10.0` 要求。Swift Package Manager 构建已在 Flutter 3.41.9 和 3.44.9 上验证；其他版本需使用满足 Dart SDK 要求且支持相应依赖管理方式的 Flutter SDK。在 Flutter 应用的 `pubspec.yaml` 中添加插件依赖：

```yaml
dependencies:
  privacy_capture_guard: ^0.1.2
```

然后在应用目录运行：

```sh
flutter config --enable-swift-package-manager
flutter pub get
flutter build ios --simulator
```

Flutter 3.41.x 请显式启用 Swift Package Manager。Flutter 会自动识别 `ios/privacy_capture_guard/Package.swift`，并提供 `FlutterFramework` 依赖，无需在 Xcode 中手动添加仓库 URL。

这是 Flutter 插件的 Swift Package，不是独立的原生 Swift SDK。Dart API 和插件注册方式保持不变。

本地开发示例时，请使用与包名一致的克隆目录名，避免 SwiftPM 本地包标识冲突：

```sh
git clone git@github.com:MyNameIsSkyFly/privacy_screen_guard.git privacy_capture_guard
cd privacy_capture_guard/example
flutter config --enable-swift-package-manager
flutter pub get
flutter build ios --simulator
```

### CocoaPods

现有 CocoaPods 项目可继续使用 `ios/privacy_capture_guard.podspec`，无需更改 Dart 调用。Swift Package Manager 和 CocoaPods 均会打包 `PrivacyInfo.xcprivacy`。

## 使用

```dart
final guard = PrivacyCaptureGuard.instance;

// 建议在第一个敏感页面显示后开启。
await guard.enable();

// 普通页面退出时可关闭。
await guard.disable();
```

### URL 跳转不黑屏

```dart
await guard.runUnprotected(() async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
});
```

### 拉起购买不黑屏

```dart
final purchaseStarted = await guard.runUnprotected(() async {
  return InAppPurchase.instance.buyConsumable(purchaseParam: param);
});
```

`runUnprotected` 会先清除原生保护、让出一次事件循环，再执行操作，并在操作结束后延迟 350ms 恢复。它使用 `try/finally` 且支持嵌套，即使跳转或购买抛异常也会恢复保护。

购买 API 如果只负责“发起购买”并立即返回，而购买弹窗生命周期更长，应将整个购买状态流包在一次放行中，或手动控制：

```dart
await guard.pause();
try {
  await startAndWaitForPurchaseCompletion();
} finally {
  await guard.resume();
}
```

## 注意事项

- 必须在前台 `Activity` 存在时调用 Android API。
- Android 使用公开的 `WindowManager.LayoutParams.FLAG_SECURE`。
- iOS 安全画布依赖 UIKit 内部视图结构，每次升级 iOS 后都应重新真机验证。
- 请在真机测试系统浏览器、微信/支付宝跳转、Google Play Billing 和 StoreKit，因为模拟器行为不同。
