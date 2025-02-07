//
//  FlutterObjectCaptureView.swift
//  flutter_object_capture
//
//  Created by Oluwafemi Oyepeju on 16/01/2025.
//
import Flutter
import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: FlutterObjectCapturePlugin.subsystem, category: "FlutterObjectCaptureView")

class FlutterObjectCaptureView: NSObject, FlutterPlatformView {
    private var objectCaptureView: UIView
    private var session: ObjectCaptureSession?
    let channel: FlutterMethodChannel

    init(
        withFrame frame: CGRect, viewIdentifier viewId: Int64, messenger msg: FlutterBinaryMessenger
    ) {
        objectCaptureView = UIView()
        channel = FlutterMethodChannel(name: "flutter_object_capture_\(viewId)", binaryMessenger: msg)

        super.init()

        createNativeView(view: objectCaptureView)
        channel.setMethodCallHandler(onMethodCalled)
    }

    func view() -> UIView {
        return objectCaptureView
    }

    private func createNativeView(view _view: UIView) {
        // Create the native view for either UIKit or SwiftUI and add it to the Flutter view.

        // FOR SWIFTUI
//        guard let session = session else {
//            print("ObjectCaptureSession is not initialized. Call startSession first.")
//            return
//        }
        
//        let captureView = UIHostingController(rootView: CaptureView())
//        let swiftUIView = captureView.view!
//        swiftUIView.translatesAutoresizingMaskIntoConstraints = false
//
//        _view.addSubview(swiftUIView)
//
//        NSLayoutConstraint.activate([
//            swiftUIView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
//            swiftUIView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
//            swiftUIView.topAnchor.constraint(equalTo: _view.topAnchor),
//            swiftUIView.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
//        ])
    }

    private func onMethodCalled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        _ = call.arguments as? [String: Any]

        if session == nil && call.method != "startSession" {
            logger.log("plugin is not initialized properly")
            result(nil)
            return
        }
        switch call.method {
        case "startSession":
            Task { @MainActor in
                 await startSession(result: result)
            }
        case "stopSession":
            Task { @MainActor in
                 stopSession(result: result)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func sendToFlutter(_ method: String, arguments: Any?) {
        DispatchQueue.main.async {
            self.channel.invokeMethod(method, arguments: arguments)
        }
    }

    @MainActor
    private func startSession(result: @escaping FlutterResult) async {
        session = ObjectCaptureSession()
        let captureFolderManager = try? CaptureFolderManager()
        var config = ObjectCaptureSession.Configuration()
        config.isOverCaptureEnabled = true
        if let folderManager = captureFolderManager {
            config.checkpointDirectory = folderManager.checkpointFolder
            // Starts the initial segment and sets the output locations.
            session?.start(imagesDirectory: folderManager.imagesFolder,
                          configuration: config)
            // Create and add CaptureView
            let captureView = UIHostingController(rootView: CaptureView(
                session: session!, captureFolderManager: folderManager,
                onProcessComplete: { resultPath in
                    self.sendToFlutter("onCompleted", arguments: resultPath)
                }
            ))
            let swiftUIView = captureView.view!
            swiftUIView.translatesAutoresizingMaskIntoConstraints = false
            
            objectCaptureView.addSubview(swiftUIView)
            
            NSLayoutConstraint.activate([
                swiftUIView.leadingAnchor.constraint(equalTo: objectCaptureView.leadingAnchor),
                swiftUIView.trailingAnchor.constraint(equalTo: objectCaptureView.trailingAnchor),
                swiftUIView.topAnchor.constraint(equalTo: objectCaptureView.topAnchor),
                swiftUIView.bottomAnchor.constraint(equalTo: objectCaptureView.bottomAnchor)
            ])
        } else {
            result(
                FlutterError(
                    code: "UNAVAILABLE",message: "Battery level not available.",
                    details: nil)
            )
        }
        
        
        result(nil)
    }

    @MainActor
    private func stopSession(result: @escaping FlutterResult) {
        session?.finish()
        session = nil
        result(nil)
    }
}
