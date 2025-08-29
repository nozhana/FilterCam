//
//  AppConfiguration.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import FilterCamBase
import FilterCamShared
import SwiftUI

extension EnvironmentValues {
#if DEBUG
    @Entry var appConfiguration = ProcessInfo.isRunningPreviews ? AppConfiguration.preview : .shared
#else
    @Entry var appConfiguration = AppConfiguration.shared
#endif
}
