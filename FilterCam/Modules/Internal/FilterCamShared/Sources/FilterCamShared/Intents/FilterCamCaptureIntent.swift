//
//  FilterCamCaptureIntent.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import AppIntents
import LockedCameraCapture

@available(iOS 18.0, *)
struct FilterCamCaptureIntent: CameraCaptureIntent {
    static let title: LocalizedStringResource = "FilterCam Capture Intent"
    static let description: IntentDescription? = "Camera Capture Intent"
    
    typealias AppContext = CameraState
    
    func perform() async throws -> some IntentResult {
        .result()
    }
}
