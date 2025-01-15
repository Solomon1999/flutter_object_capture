import RealityKit
import SwiftUI


var session = ObjectCaptureSession()
var configuration  = ObjectCaptureSession.Configuration()
configuration.checkpointDirectory = getDocumentsDir().appendingPathComponent("Snapshots/")

session.start(
    imageDirectory: getDocumentsDir().appendingPathComponent("Images/"),
    configuration: configuration
)

struct CaptureView: View {
    var body: some View {
        if (session.userCompletedScanPass) {
            VStack {
                // Scanned Model
                ObjectCapturePointCloudView(session: session)

                Spacer()

                VStack(spacing: 12) {
                    CreateButton(label: "Continue Scanning") {
                        
                    }

                    CreateButton(label: "Finish") {
                        session.finish()
                    }
                }
            } 
        } else {
            ZStack {
                ObjectCaptureView(session: session),
                
                if case .ready = session.state {
                    CreateButton(label: "Continue") {
                        session.startDetecting()
                    }
                } else if case .detecting = session.state {
                    CreateButton(label: "Start Capture") {
                        session.startCapturing()
                    }
                }
            }
        }
    }
}