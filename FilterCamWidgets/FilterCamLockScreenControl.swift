//
//  FilterCamLockScreenControl.swift
//  FilterCamWidgets
//
//  Created by Nozhan A. on 8/20/25.
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 18.0, *)
struct FilterCamLockScreenControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.nozhana.FilterCam.FilterCamWidgets"
        ) {
            ControlWidgetButton(action: FilterCamCaptureIntent()) {
                Image(systemName: "camera.aperture")
            }
        }
        .displayName("FilterCam")
        .description("Quickly capture photos on your lock screen with FilterCam.")
    }
}
