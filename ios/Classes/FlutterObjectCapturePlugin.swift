import Flutter
import RealityKit
import UIKit


public class FlutterObjectCapturePlugin: NSObject, FlutterPlugin {
  static let subsystem = "flutter_object_capture"
  static let minNumImages = 10

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "flutter_object_capture", binaryMessenger: registrar.messenger())
    let instance = FlutterObjectCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
  }
}

class FlutterObjectCaptureFactory: NSObject, FlutterPlatformViewFactory {
  let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments _: Any?)
    -> FlutterPlatformView
  {
    let view = FlutterObjectCaptureView(
      withFrame: frame, viewIdentifier: viewId, messenger: messenger)
    return view
  }
}
