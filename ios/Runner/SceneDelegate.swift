import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private static let captureProtectionChannelName = "zinme_app/capture_protection"
  private var captureProtectionChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    configureCaptureProtectionChannel()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    configureCaptureProtectionChannel()
    notifyScreenCaptureState()
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    NotificationCenter.default.removeObserver(self)
    super.sceneDidDisconnect(scene)
  }

  private func configureCaptureProtectionChannel() {
    guard captureProtectionChannel == nil,
      let controller = window?.rootViewController as? FlutterViewController
    else {
      return
    }

    let channel = FlutterMethodChannel(
      name: Self.captureProtectionChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "isScreenCaptured":
        result(self?.isScreenCaptured() ?? false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    captureProtectionChannel = channel
  }

  @objc private func screenCaptureChanged() {
    notifyScreenCaptureState()
  }

  private func notifyScreenCaptureState() {
    captureProtectionChannel?.invokeMethod(
      "screenCaptureChanged",
      arguments: isScreenCaptured()
    )
  }

  private func isScreenCaptured() -> Bool {
    return UIScreen.main.isCaptured
  }
}
