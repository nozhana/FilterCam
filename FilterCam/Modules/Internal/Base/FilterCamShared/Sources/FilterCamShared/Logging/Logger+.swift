//
//  Logger+.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation
import OSLog

extension Logger {
    static let shared = Logger(subsystem: "com.nozhana.FilterCam.logger", category: "shared")
}

let logger = Logger.shared
