//
//  FilterCamCaptureIntent.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import AppIntents
import LockedCameraCapture

@available(iOS 18.0, *)
public struct FilterCamCaptureIntent: CameraCaptureIntent {
    public init() {}
    
    public static let title: LocalizedStringResource = "FilterCam Capture Intent"
    public static let description: IntentDescription? = "Camera Capture Intent"
    
    public typealias AppContext = CameraState
    
    public func perform() async throws -> some IntentResult {
        .result()
    }
}
