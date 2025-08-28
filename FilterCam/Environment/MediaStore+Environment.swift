//
//  MediaStore+Environment.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import FilterCamBase
import SwiftUI

extension EnvironmentValues {
#if DEBUG
    @Entry var mediaStore = ProcessInfo.isRunningPreviews ? MediaStore.preview : .shared
#else
    @Entry var mediaStore = MediaStore.shared
#endif
}
