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
    @State var session: ObjectCaptureSession {
        willSet {
            detachListeners()
        }
        didSet {
            attachListeners()
        }
    }
    @State var captureFolderManager: CaptureFolderManager?
    var onProcessComplete: (String) -> Void
    
    @State private var currentFeedback: Set<Feedback> = []
    
    private typealias Feedback = ObjectCaptureSession.Feedback
    private typealias Tracking = ObjectCaptureSession.Tracking
    
    @State private var tasks: [ Task<Void, Never> ] = []
    @State private var messageList = TimedMessageList()
    @State private var isObjectFlipped = false
    
    @State private var captureMode = CaptureMode.object
    @State private var showReconstructionView: Bool = false
    @State private var showShotLocations: Bool = false
    
    @State private var photoSession: PhotogrammetrySession?
    
    
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
    
    private func startObjectReconstruction() {
        session.finish()
        if let folderManager = captureFolderManager {
            var config = PhotogrammetrySession.Configuration()
            if captureMode == .area {
                config.isObjectMaskingEnabled = false
            }
            
            config.checkpointDirectory = folderManager.checkpointFolder
            photoSession = try? PhotogrammetrySession(
                input: folderManager.imagesFolder,
                configuration: config
            )
            if let photoSession = photoSession {
                showReconstructionView = true
            } else {
                logger.log("Failed to create PhotgrammetrySession")
            }
        } else {
            logger.log("Capture Folder Manager unexpectedly nil!")
        }
        
    }
    
    var body: some View {
        
        if session.userCompletedScanPass {
            VStack {
                ObjectCapturePointCloudView(
                    session: session
                )
                // .showShotLocations(showShotLocations)
                Spacer()
                HStack(spacing: 12) {
                    Button(action: {
                        session.startCapturing()
                    }) {
                        Text("Rescan")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 20)
                            .clipShape(Capsule())
                    }
                    Button(action: {
                        startObjectReconstruction()
                    }) {
                        Text("Finish")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 20)
                            .background(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showReconstructionView) {
                if let folderManager = captureFolderManager {
                    if let photoSession = photoSession {
                        ReconstructionView(
                            outputFile: folderManager.modelsFolder.appendingPathComponent("model-mobile.usdz"),
                            photogrammetrySession: photoSession,
                            onComplete: { outputFilePath in
                                onProcessComplete(outputFilePath.absoluteString)
                            }
                        )
                        .interactiveDismissDisabled()
                    }
//                    else {
//                        preconditionFailure("Failed to create Photogrammetry session")
//                    }
                }
//                else {
//                    preconditionFailure("Capture Folder Manager unexpectedly nil!")
//                }
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
