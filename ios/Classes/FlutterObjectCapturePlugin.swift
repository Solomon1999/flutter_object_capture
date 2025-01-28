import Flutter
import RealityKit
import UIKit


public class FlutterObjectCapturePlugin: NSObject, FlutterPlugin {
    static let subsystem = "flutter_object_capture"
    static let minNumImages = 10
    public static var registrar: FlutterPluginRegistrar? = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        FlutterObjectCapturePlugin.registrar = registrar
        let objectCaptureFactory = FlutterObjectCaptureFactory(messenger: registrar.messenger())
        registrar.register(objectCaptureFactory, withId: "flutter_object_capture")

        let channel = FlutterMethodChannel(name: "flutter_object_capture", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(FlutterObjectCapturePlugin(), channel: channel)
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
