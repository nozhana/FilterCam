//
//  OpenMainAppAction.swift
//  FilterCamCaptureExtension
//
//  Created by Nozhan A. on 8/20/25.
//

import LockedCameraCapture
import SwiftUI

struct OpenMainAppAction {
    private let openAction: ((NSUserActivity) async throws -> Void)?
    private let userActivity: NSUserActivity?
    
    @available(iOS 18.0, *)
    init(session: LockedCameraCaptureSession, userActivity: NSUserActivity? = nil) {
        self.openAction = session.openApplication
        self.userActivity = userActivity ?? .init(activityType: NSUserActivityTypeLockedCameraCapture)
    }
    
    init() {
        self.openAction = nil
        self.userActivity = nil
    }
    
    func callAsFunction() async throws {
        guard let openAction, let userActivity else { return }
        try await openAction(userActivity)
    }
    
    var isNoop: Bool {
        openAction == nil
    }
}

extension EnvironmentValues {
    @Entry var openMainApp = OpenMainAppAction()
}
