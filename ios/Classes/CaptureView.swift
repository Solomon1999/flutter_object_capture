//
//  BaseObjectCaptureView.swift
//  flutter_object_capture
//
//  Created by Oluwafemi Oyepeju on 16/01/2025.
//

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: FlutterObjectCapturePlugin.subsystem, category: "CaptureView")

enum CaptureMode: Equatable {
    case object
    case area
}

struct CaptureView: View {
    @State private var session: ObjectCaptureSession = ObjectCaptureSession() {
        willSet {
            detachListeners()
        }
        didSet {
            attachListeners()
        }
    }
    
    @State private var currentFeedback: Set<Feedback> = []
    
    private typealias Feedback = ObjectCaptureSession.Feedback
    private typealias Tracking = ObjectCaptureSession.Tracking
    
    @State private var tasks: [ Task<Void, Never> ] = []
    @State private var messageList = TimedMessageList()
    @State private var isObjectFlipped = false
    
    @State private var captureMode = CaptureMode.object
    @State private(set) var captureFolderManager: CaptureFolderManager?
    @State private var showReconstructionView: Bool = false
    @State private var showShotLocations: Bool = false
    
    private func attachListeners() {
        logger.debug("Attaching listeners...")
        let model = session
        
        tasks.append(
            Task<Void, Never> {
                for await newFeedback in model.feedbackUpdates {
                    logger.debug("Task got async feedback change to: \(String(describing: newFeedback))")
                    self.updateFeedbackMessages(for: newFeedback)
                }
                logger.log("^^^ Got nil from stateUpdates iterator!  Ending observation task...")
            })
        
    }
    
    
    private func detachListeners() {
        logger.debug("Detaching listeners...")
        for task in tasks {
            task.cancel()
        }
        tasks.removeAll()
    }
    
    private func updateFeedbackMessages(for feedback: Set<Feedback>) {
        // Compare the incoming feedback with the previous feedback to find the intersection.
        let persistentFeedback = currentFeedback.intersection(feedback)
        
        // Find the feedbacks that are not active anymore.
        let feedbackToRemove = currentFeedback.subtracting(persistentFeedback)
        for thisFeedback in feedbackToRemove {
            if let feedbackString = FeedbackMessages.getFeedbackString(for: thisFeedback, captureMode: captureMode) {
                messageList.remove(feedbackString)
            }
        }
        
        // Find the new feedbacks.
        let feebackToAdd = feedback.subtracting(persistentFeedback)
        for thisFeedback in feebackToAdd {
            if let feedbackString = FeedbackMessages.getFeedbackString(for: thisFeedback, captureMode: captureMode) {
                messageList.add(feedbackString)
            }
        }
        
        currentFeedback = feedback
    }
    
    var body: some View {
        
        if session.userCompletedScanPass {
            VStack {
                ObjectCapturePointCloudView(
                    session: session
                )
                // .showShotLocations(showShotLocations)
                Spacer()
                Button(action: {
                    session.startCapturing()
                }) {
                    Text("Rescan")
                }
                Button(action: {
                    session.finish()
                    showReconstructionView = true
                }) {
                    Text("Finish")
                }
            }
            .sheet(isPresented: $showReconstructionView) {
                if let folderManager = captureFolderManager {
                    ReconstructionView(
                        outputFile: folderManager.modelsFolder.appendingPathComponent("model-mobile.usdz"))
                    .interactiveDismissDisabled()
                } else {
                    preconditionFailure("captureFolderManager unexpectedly nil!")
                }
            }
        } else {
            ZStack {
                ObjectCaptureView(
                    session: session,
                    cameraFeedOverlay: { GradientBackground() }
                )
                // .hideObjectReticle(captureMode == .area)
                .transition(.opacity)
                CaptureActionsView(
                    session: session, captureMode: $captureMode,
                    captureFolderManager: captureFolderManager,
                    messageList: messageList, isObjectFlipped: $isObjectFlipped
                )
            }
            .onAppear(perform: {
                UIApplication.shared.isIdleTimerDisabled = true
            })
            .id(session.id)
        }
    }
    
    private struct GradientBackground: View {
        private let gradient = LinearGradient(
            colors: [.black.opacity(0.4), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        private let frameHeight: CGFloat = 300
        
        var body: some View {
            VStack {
                gradient
                    .frame(height: frameHeight)
                
                Spacer()
                
                gradient
                    .rotation3DEffect(Angle(degrees: 180), axis: (x: 1, y: 0, z: 0))
                    .frame(height: frameHeight)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}
