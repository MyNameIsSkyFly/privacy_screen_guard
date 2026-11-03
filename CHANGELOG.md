## 0.1.2

- Remove the explicit Flutter SDK version constraint; retain Dart SDK ^3.10.0.
- Add iOS Swift Package Manager support, verified with Flutter 3.41.9 and 3.44.9.
- Share iOS sources between Swift Package Manager and CocoaPods.
- Bundle the existing privacy manifest with both dependency managers.

## 0.1.1

- Support Dart SDK 3.10 and later.
- Prevent the hidden iOS secure-canvas field from reopening the keyboard.

## 0.1.0

- Add Android screenshot and screen-recording protection with `FLAG_SECURE`.
- Add experimental iOS screenshot protection using a secure input canvas.
- Add black screen-recording and app-switcher protection on iOS.
- Add nested temporary bypasses for URL, image picker, cropper, and purchase flows.
- Restore protection automatically when an external flow succeeds or throws.
