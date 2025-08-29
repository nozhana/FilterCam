//
//  ProcessInfo+.swift
//  FilterCamUtilities
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

public extension ProcessInfo {
    var isRunningPreviews: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    static var isRunningPreviews: Bool { processInfo.isRunningPreviews }
}
