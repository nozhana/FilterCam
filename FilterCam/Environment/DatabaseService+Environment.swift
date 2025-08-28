//
//  DatabaseService+Environment.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import FilterCamBase
import SwiftUI

extension EnvironmentValues {
#if DEBUG
    @Entry var database: DatabaseService = ProcessInfo.isRunningPreviews ? .inMemory : .default
#else
    @Entry var database: DatabaseService = .default
#endif
}
