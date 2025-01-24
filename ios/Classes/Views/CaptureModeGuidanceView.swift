//
//  CaptureGuidanceView.swift
//  flutter_object_capture
//
//  Created by Oluwafemi Oyepeju on 23/01/2025.
//

import SwiftUI

struct CaptureModeGuidanceView: View {
    var captureMode: CaptureMode
    
    var body: some View {
        Text(guidanceText)
            .font(.subheadline)
            .bold()
            .padding(.all, 6)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(5)
    }

    private var guidanceText: String {
        switch captureMode {
            case .object:
                return LocalizedString.objectMode
            case .area:
                return LocalizedString.areaMode
        }
    }

    private struct LocalizedString {
        static let areaMode = NSLocalizedString(
            "Area mode (Object Capture)",
            bundle: Bundle.main,
            value: "AREA MODE",
            comment: "Title for the Area Mode guidance text.")

        static let objectMode = NSLocalizedString(
            "Object mode (Object Capture)",
            bundle: Bundle.main,
            value: "OBJECT MODE",
            comment: "Title for the Object Mode guidance text.")
    }
}

#Preview {
    CaptureModeGuidanceView(
        captureMode: CaptureMode.object
    )
}
