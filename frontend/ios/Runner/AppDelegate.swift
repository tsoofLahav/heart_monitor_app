import Flutter
import UIKit
import Mute
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MonitorSoundStatus") {
      MonitorSoundStatus.register(with: registrar)
    }
  }
}

// sound_mode returns its cached value immediately. This bridge waits for the
// next Mute probe, including after a foreground transition. No private APIs.
final class MonitorSoundStatus: NSObject, FlutterPlugin {
  private var pending: [UUID: FlutterResult] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MonitorSoundStatus()
    let channel = FlutterMethodChannel(name: "monitor/sound", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
    Mute.shared.alwaysNotify = true
    Mute.shared.notify = { [weak instance] silent in
      guard let instance = instance else { return }
      let callbacks = instance.pending
      instance.pending.removeAll()
      callbacks.values.forEach { $0(silent) }
    }
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "readVolume" {
      result(Double(AVAudioSession.sharedInstance().outputVolume))
      return
    }
    guard call.method == "readSilent" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard UIApplication.shared.applicationState == .active else {
      result(FlutterError(code: "inactive", message: "Sound check requires foreground", details: nil))
      return
    }
    let requestID = UUID()
    pending[requestID] = result
    Mute.shared.check()
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
      guard let callback = self?.pending.removeValue(forKey: requestID) else { return }
      callback(FlutterError(code: "timeout", message: "Silent-mode probe did not finish", details: nil))
    }
  }
}
