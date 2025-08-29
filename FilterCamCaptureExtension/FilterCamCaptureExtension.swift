//
//  FilterCamCaptureExtension.swift
//  FilterCamCaptureExtension
//
//  Created by Nozhan A. on 8/20/25.
//

import FilterCamShared
import Foundation
import LockedCameraCapture
import SwiftUI

@main
struct FilterCamCaptureExtension: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            let appConfiguration = AppConfiguration(captureDirectory: session.sessionContentURL)
            return CameraViewFinder()
                .environment(\.scenePhase, .active)
                .environment(\.appConfiguration, appConfiguration)
                .environment(\.openMainApp, .init(session: session))
                .environment(\.mediaStore, .init(appConfiguration: appConfiguration))
        }
    }
}
