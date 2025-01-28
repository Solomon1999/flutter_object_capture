//
//  TopCaptureActionsView.swift
//  flutter_object_capture
//
//  Created by Oluwafemi Oyepeju on 23/01/2025.
//

import RealityKit
import SwiftUI
import os

private let logger = Logger(subsystem: FlutterObjectCapturePlugin.subsystem, category: "TopCaptureActionsView")

struct TopCaptureActionsView: View, OverlayButtons {
    var session: ObjectCaptureSession
    var captureFolderManager: CaptureFolderManager?
    
    @Binding var captureMode: CaptureMode
    
    var showCaptureModeGuidance: Bool
    
    var body: some View {
        VStack {
            HStack {
                CaptureCancelButton()
                Spacer()
                if !isCapturingStarted(state: session.state) {
                    CaptureFolderButton(
                        objectCaptureSession: session,
                        captureFolderManager: captureFolderManager
                    )
                }
            }
            .foregroundColor(.white)
            Spacer().frame(height: 26)
            if session.state == .ready, showCaptureModeGuidance {
                CaptureModeGuidanceView(captureMode: captureMode)
            }
        }
    }
}

private struct CaptureCancelButton: View {
    var objectCaptureSession: ObjectCaptureSession?
    var captureFolderManager: CaptureFolderManager?
    
    var body: some View {
        Button(action: {
            logger.log("\(LocalizedString.cancel) button clicked!")
            objectCaptureSession?.cancel()
            captureFolderManager?.removeCaptureFolder()
        }, label: {
            Text(LocalizedString.cancel)
                .modifier(VisualEffectRoundedCorner())
        })
    }

    struct LocalizedString {
        static let cancel = NSLocalizedString(
            "Cancel (Object Capture)",
            bundle: Bundle.main,
            value: "Cancel",
            comment: "Title for the Cancel button on the object capture screen.")
    }
}


private struct CaptureFolderButton: View {
    var objectCaptureSession: ObjectCaptureSession?
    var captureFolderManager: CaptureFolderManager?
    
    @State  var showCaptureFolders: Bool = false

    var body: some View {
        Button(action: {
            logger.log("Capture folder button clicked!")
            showCaptureFolders = true
        }, label: {
            Image(systemName: "folder")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22)
                .foregroundColor(.white)
                .padding(20)
                .contentShape(.rect)
        })
        .padding(-20)
        .sheet(isPresented: $showCaptureFolders) {
            GalleryView(
                showCaptureFolders: $showCaptureFolders,
                captureFolderManager: captureFolderManager
            )
        }
        .onChange(of: showCaptureFolders) {
            if showCaptureFolders {
                objectCaptureSession?.pause()
            } else {
                objectCaptureSession?.resume()
            }
        }
    }
}

private struct VisualEffectRoundedCorner: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16.0)
            .font(.subheadline)
            .bold()
            .foregroundColor(.white)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .cornerRadius(15)
            .multilineTextAlignment(.center)
    }
}

private struct GalleryView: View {
    @Binding var showCaptureFolders: Bool
    var captureFolderManager: CaptureFolderManager?

    var body: some View {
        if let captureFolderURLs {
            ScrollView {
                ZStack {
                    HStack {
                        Button(LocalizedString.cancel) {
                            logger.log("The cancel button in gallery view clicked!")
                            withAnimation {
                                showCaptureFolders = false
                            }
                        }
                        .foregroundColor(.accentColor)
                        Spacer()
                    }
                    Text(LocalizedString.captures)
                        .foregroundColor(.primary).bold()
                }
                Divider().padding(.vertical, 8)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()),
                                         count: UIDevice.current.userInterfaceIdiom == .pad ? 5 : 3)) {
                    let frameWidth = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 115
                    ForEach(captureFolderURLs, id: \.self) { url in
                        ThumbnailView(captureFolderURL: url, frameSize: CGSize(width: frameWidth, height: frameWidth + 70))
                    }
                }
            }.padding()
        }
    }

    private var captureFolderURLs: [URL]? {
        guard let topLevelFolder = captureFolderManager?.appDocumentsFolder else { return nil }
        let folderURLs = try? FileManager.default.contentsOfDirectory(
            at: topLevelFolder,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { $0.hasDirectoryPath }
            .sorted(by: { $0.path > $1.path })
        guard let folderURLs else { return nil }
        print("FOLDER URLS: \(folderURLs)");
        return folderURLs
    }

    struct LocalizedString {
        static let cancel = NSLocalizedString(
            "Cancel (Object Capture)",
            bundle: Bundle.main,
            value: "Cancel",
            comment: "Title for the Cancel button on the folder view.")

        static let captures = NSLocalizedString(
            "Captures (Object Capture)",
            bundle: Bundle.main,
            value: "Captures",
            comment: "Title for the folder view.")
    }
}

private struct ThumbnailView: View {
    let captureFolderURL: URL
    let frameSize: CGSize
    @State private var image: CGImage?

    var body: some View {
        if let imageURL = getFirstImage(from: captureFolderURL) {
            ShareLink(item: captureFolderURL) {
                VStack(spacing: 8) {
                    VStack {
                        if let image {
                            Image(decorative: image, scale: 1.0)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: frameSize.width, height: frameSize.width)
                    .clipped()
                    .cornerRadius(6)

                    let folderName = captureFolderURL.lastPathComponent
                    Text("\(folderName)")
                        .foregroundColor(.primary)
                        .font(.caption2)
                    Spacer()
                }
                .frame(width: frameSize.width, height: frameSize.height)
                .task {
                    image = await createThumbnail(url: imageURL)
                }
            }
        }
    }

    private nonisolated func createThumbnail(url: URL) async -> CGImage? {
        let options = [
            kCGImageSourceThumbnailMaxPixelSize: frameSize.width * 2,
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else {
            return nil
        }
        return thumbnail
    }

    private func getFirstImage(from url: URL) -> URL? {
        let imageFolderURL = url.appendingPathComponent(CaptureFolderManager.imagesFolderName)
        let imagesURL: URL? = try? FileManager.default.contentsOfDirectory(
            at: imageFolderURL,
            includingPropertiesForKeys: nil,
            options: [])
            .filter { !$0.hasDirectoryPath }
            .sorted(by: { $0.path < $1.path })
            .first
        return imagesURL
    }
}
