//
//  CaptureActionsView.swift
//  flutter_object_capture
//
//  Created by Oluwafemi Oyepeju on 23/01/2025.
//

import RealityKit
import SwiftUI

struct CaptureActionsView: View {
    var session: ObjectCaptureSession
    @Binding var captureMode: CaptureMode
    var messageList: TimedMessageList
    
    @Binding var isObjectFlipped: Bool
    
    @State private var showCaptureModeGuidance: Bool = false
    @State private var hasDetectionFailed = false
    @State private var showTutorialView = false
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    private var rotationAngle: Angle {
        switch deviceOrientation {
            case .landscapeLeft:
                return Angle(degrees: 90)
            case .landscapeRight:
                return Angle(degrees: -90)
            case .portraitUpsideDown:
                return Angle(degrees: 180)
            default:
                return Angle(degrees: 0)
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                TopCaptureActionsView(
                    session: session,
                    captureMode: $captureMode,
                    showCaptureModeGuidance: showCaptureModeGuidance
                )

                Spacer()

                BoundingBoxGuidanceView(
                    session: session,
                    captureMode: $captureMode,
                    hasDetectionFailed: hasDetectionFailed
                )

                BottomCaptureActionsView(
                    session: session,
                    captureMode: $captureMode,
                    isObjectFlipped: $isObjectFlipped,
                    hasDetectionFailed: $hasDetectionFailed,
                    showCaptureModeGuidance: $showCaptureModeGuidance,
                    showTutorialView: $showTutorialView,
                    rotationAngle: rotationAngle
                )
            }
            .padding()
            .padding(.horizontal, 15)
            .background {
                VStack {
                    Spacer().frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 65 : 25)

                    FeedbackView(messageList: messageList)
                        .layoutPriority(1)
                }
                .rotationEffect(rotationAngle)
            }
            .task {
                for await _ in NotificationCenter.default.notifications(named: UIDevice.orientationDidChangeNotification) {
                    withAnimation {
                        deviceOrientation = UIDevice.current.orientation
                    }
                }
            }
        }
    }
}

private struct BoundingBoxGuidanceView: View {
    var session: ObjectCaptureSession
    @Binding var captureMode: CaptureMode
    var hasDetectionFailed: Bool

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        HStack {
            if let guidanceText {
                Text(guidanceText)
                    .font(.callout)
                    .bold()
                    .foregroundColor(.white)
                    .transition(.opacity)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 400 : 360)
            }
        }
    }

    private var guidanceText: String? {
        if case .ready = session.state {
            switch captureMode {
                case .object:
                    if hasDetectionFailed {
                        return NSLocalizedString(
                            "Can‘t find your object. It should be larger than 3 in (8 cm) in each dimension.",
                            bundle: Bundle.main,
                            value: "Can‘t find your object. It should be larger than 3 in (8 cm) in each dimension.",
                            comment: "Feedback message when detection has failed.")
                    } else {
                        return NSLocalizedString(
                            "Move close and center the dot on your object, then tap Continue. (Object Capture, State)",
                            bundle: Bundle.main,
                            value: "Move close and center the dot on your object, then tap Continue.",
                            comment: "Feedback message to fill the camera feed with the object.")
                    }
                case .area:
                    return NSLocalizedString(
                        "Look at your subject (Object Capture, State).",
                        bundle: Bundle.main,
                        value: "Look at your subject.",
                        comment: "Feedback message to look at the subject in the area mode.")
            }
        } else if case .detecting = session.state {
            return NSLocalizedString(
                "Move around to ensure that the whole object is inside the box. Drag handles to manually resize. (Object Capture, State)",
                bundle: Bundle.main,
                value: "Move around to ensure that the whole object is inside the box. Drag handles to manually resize.",
                comment: "Feedback message to resize the box to the object.")
        } else {
            return nil
        }
    }
}

protocol OverlayButtons {
    func isCapturingStarted(state: ObjectCaptureSession.CaptureState) -> Bool
}

extension OverlayButtons {
    func isCapturingStarted(state: ObjectCaptureSession.CaptureState) -> Bool {
        switch state {
            case .initializing, .ready, .detecting:
                return false
            default:
                return true
        }
    }
}


