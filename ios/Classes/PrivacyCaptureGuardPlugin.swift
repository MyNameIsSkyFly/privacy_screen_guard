import Flutter
import UIKit

public final class PrivacyCaptureGuardPlugin: NSObject, FlutterPlugin {
  private var enabled = false
  private var pauseDepth = 0
  private weak var shieldView: UIView?
  private var secureField: UITextField?
  private var pendingSecureField: UITextField?
  private weak var protectedView: UIView?
  private weak var protectedSuperview: UIView?
  private var protectedViewIndex = 0
  private var installGeneration = 0
  private var installResults: [FlutterResult] = []
  private var observers: [NSObjectProtocol] = []

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "privacy_capture_guard",
      binaryMessenger: registrar.messenger()
    )
    let instance = PrivacyCaptureGuardPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.startObserving()
  }

  deinit {
    observers.forEach(NotificationCenter.default.removeObserver)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        result(FlutterError(code: "UNAVAILABLE", message: "Plugin was released", details: nil))
        return
      }
      switch call.method {
      case "enable":
        self.enabled = true
        if self.pauseDepth > 0 || self.secureField != nil {
          result(nil)
        } else {
          self.installResults.append(result)
          self.startSecureCanvasInstallIfNeeded()
        }
      case "disable":
        self.enabled = false
        self.pauseDepth = 0
        self.finishInstall(with: FlutterError(
          code: "INSTALL_CANCELLED",
          message: "Protection was disabled before installation completed",
          details: nil
        ))
        self.refreshProtection()
        result(nil)
      case "pause":
        self.pauseDepth += 1
        self.finishInstall(with: FlutterError(
          code: "INSTALL_CANCELLED",
          message: "Protection was paused before installation completed",
          details: nil
        ))
        self.refreshProtection()
        result(nil)
      case "resume":
        self.pauseDepth = max(0, self.pauseDepth - 1)
        if self.enabled && self.pauseDepth == 0 && self.secureField == nil {
          self.installResults.append(result)
          self.startSecureCanvasInstallIfNeeded()
        } else {
          self.refreshProtection()
          result(nil)
        }
      case "isEnabled":
        result(self.enabled)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func startObserving() {
    let center = NotificationCenter.default
    observers.append(center.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in self?.refreshProtection() })
    observers.append(center.addObserver(
      forName: UIApplication.willResignActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in self?.showFallbackShield(force: true) })
    observers.append(center.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in self?.refreshProtection() })
  }

  private func refreshProtection() {
    let shouldProtect = enabled && pauseDepth == 0
    if shouldProtect {
      startSecureCanvasInstallIfNeeded()
    } else {
      removeSecureCanvas()
    }
    showFallbackShield(force: UIScreen.main.isCaptured)
  }

  private func showFallbackShield(force: Bool) {
    // The visible overlay is only needed if the private secure canvas cannot be found.
    let shouldShow = enabled && pauseDepth == 0 && secureField == nil && force
    guard shouldShow else {
      shieldView?.removeFromSuperview()
      return
    }
    guard shieldView == nil, let window = activeWindow() else { return }

    let shield = UIView(frame: window.bounds)
    shield.backgroundColor = .black
    shield.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    shield.isUserInteractionEnabled = false
    shield.accessibilityIdentifier = "PrivacyCaptureGuardShield"
    window.addSubview(shield)
    window.bringSubviewToFront(shield)
    shieldView = shield
  }

  private func startSecureCanvasInstallIfNeeded(rootAttempt: Int = 0) {
    guard secureField == nil, pendingSecureField == nil else { return }
    guard let window = activeWindow(),
          let rootView = window.rootViewController?.viewIfLoaded,
          let rootSuperview = rootView.superview else {
      if rootAttempt < 20 && enabled && pauseDepth == 0 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
          self?.startSecureCanvasInstallIfNeeded(rootAttempt: rootAttempt + 1)
        }
        return
      }
      finishInstall(with: FlutterError(
        code: "NO_ROOT_VIEW",
        message: "Flutter root view is not attached yet; call enable() after the first frame",
        details: nil
      ))
      return
    }

    let field = UITextField(frame: rootView.frame)
    field.backgroundColor = .black
    field.borderStyle = .none
    field.textColor = .clear
    field.tintColor = .clear
    field.text = " "
    field.isSecureTextEntry = true
    field.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    field.accessibilityIdentifier = "PrivacyCaptureGuardSecureField"
    let originalIndex = rootSuperview.subviews.firstIndex(of: rootView) ?? 0
    rootSuperview.insertSubview(field, at: originalIndex)
    pendingSecureField = field
    installGeneration += 1
    tryAttachSecureCanvas(
      field: field,
      window: window,
      rootView: rootView,
      rootSuperview: rootSuperview,
      originalIndex: originalIndex,
      attempt: 0,
      generation: installGeneration
    )
  }

  private func tryAttachSecureCanvas(
    field: UITextField,
    window: UIWindow,
    rootView: UIView,
    rootSuperview: UIView,
    originalIndex: Int,
    attempt: Int,
    generation: Int
  ) {
    guard generation == installGeneration,
          enabled && pauseDepth == 0,
          field.window === window,
          rootView.superview === rootSuperview else { return }

    window.layoutIfNeeded()
    field.setNeedsLayout()
    field.layoutIfNeeded()

    guard let canvas = findSecureCanvas(in: field) else {
      guard attempt < 20 else {
        pendingSecureField = nil
        field.removeFromSuperview()
        finishInstall(with: FlutterError(
          code: "SECURE_CANVAS_UNAVAILABLE",
          message: "This iOS version did not expose a secure text canvas; screenshot protection is not active",
          details: nil
        ))
        return
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
        self?.tryAttachSecureCanvas(
          field: field,
          window: window,
          rootView: rootView,
          rootSuperview: rootSuperview,
          originalIndex: originalIndex,
          attempt: attempt + 1,
          generation: generation
        )
      }
      return
    }

    protectedViewIndex = originalIndex
    protectedView = rootView
    protectedSuperview = rootSuperview
    rootView.removeFromSuperview()
    canvas.frame = field.bounds
    canvas.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    canvas.isUserInteractionEnabled = true
    rootView.frame = canvas.bounds
    rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    canvas.addSubview(rootView)
    pendingSecureField = nil
    secureField = field
    shieldView?.removeFromSuperview()
    finishInstall(with: nil)
  }

  private func finishInstall(with value: Any?) {
    let results = installResults
    installResults.removeAll()
    results.forEach { $0(value) }
  }

  private func removeSecureCanvas() {
    installGeneration += 1
    if let pendingField = pendingSecureField {
      pendingField.removeFromSuperview()
      pendingSecureField = nil
    }
    guard let field = secureField else { return }
    if let rootSuperview = protectedSuperview, let rootView = protectedView {
      rootView.removeFromSuperview()
      let index = min(protectedViewIndex, rootSuperview.subviews.count)
      rootSuperview.insertSubview(rootView, at: index)
      rootView.frame = field.frame
      rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    field.removeFromSuperview()
    secureField = nil
    protectedView = nil
    protectedSuperview = nil
  }

  private func findSecureCanvas(in view: UIView) -> UIView? {
    for child in view.subviews {
      let className = String(describing: type(of: child))
      if className.contains("CanvasView") {
        return child
      }
      if let canvas = findSecureCanvas(in: child) {
        return canvas
      }
    }
    return nil
  }

  private func activeWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .filter { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
        .flatMap(\.windows)
        .first(where: \.isKeyWindow)
    }
    return UIApplication.shared.keyWindow
  }
}
