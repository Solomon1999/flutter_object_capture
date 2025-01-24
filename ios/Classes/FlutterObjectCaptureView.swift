//
//  FlutterObjectCaptureView.swift
//  flutter_object_capture
//
//  Created by Oluwafemi Oyepeju on 16/01/2025.
//
import Flutter
import RealityKit
import SwiftUI

class FlutterObjectCaptureView: NSObject, FlutterPlatformView {
    private var objectCaptureView: UIView
    let channel: FlutterMethodChannel
    
    init(withFrame frame: CGRect, viewIdentifier viewId: Int64, messenger msg: FlutterBinaryMessenger) {
        objectCaptureView = UIView(frame: frame)
        channel = FlutterMethodChannel(name: "object_capture_\(viewId)", binaryMessenger: msg)
        
        super.init()
        
        // objectCaptureView.delegate = self
        createNativeView(view: objectCaptureView)
        channel.setMethodCallHandler(onMethodCalled)
        
    }
    
    func view() -> UIView { return objectCaptureView }
    
    func createNativeView(view _view: UIView){
            // Create the native view for either UIKit or SwiftUI and add it to the Flutter view.
            
            // FOR UIKIT
            // Uncomment the following code for UIKit integration.
            /*
            _view.backgroundColor = UIColor.blue
            let nativeLabel = UILabel()
            nativeLabel.text = "Native text from iOS"
            nativeLabel.textColor = UIColor.white
            nativeLabel.textAlignment = .center
            nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
            _view.addSubview(nativeLabel)
            */
            
            // FOR SWIFTUI
            let keyWindows = UIApplication.shared.windows.first(where: { $0.isKeyWindow}) ?? UIApplication.shared.windows.first
            let topController = keyWindows?.rootViewController
            let vc = UIHostingController(rootView: CaptureView())
            let swiftUiView = vc.view!
            swiftUiView.translatesAutoresizingMaskIntoConstraints = false
            
            topController?.addChild(vc)
            _view.addSubview(swiftUiView)
            
            NSLayoutConstraint.activate(
                [
                    swiftUiView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                    swiftUiView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                    swiftUiView.topAnchor.constraint(equalTo: _view.topAnchor),
                    swiftUiView.bottomAnchor.constraint(equalTo:  _view.bottomAnchor)
                ])
            
            vc.didMove(toParent: topController)
        }
    
    func onMethodCalled(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]

        switch call.method {
        case "getPlatformVersion":
          result("iOS " + UIDevice.current.systemVersion)
        default:
          result(FlutterMethodNotImplemented)
        }
    }
}
