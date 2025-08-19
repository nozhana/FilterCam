//
//  CameraError.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

enum CameraError: LocalizedError, CustomStringConvertible {
    case videoDeviceUnavailable
    case audioDeviceUnavailable
    case addInputFailed
    case addOutputFailed
    case setupFailed
    case deviceChangeFailed
    
    var description: String {
        switch self {
        case .videoDeviceUnavailable:
            "Video Device Unavailable"
        case .audioDeviceUnavailable:
            "Audio Device Unavailable"
        case .addInputFailed:
            "Add Input Failed"
        case .addOutputFailed:
            "Add Output Failed"
        case .setupFailed:
            "Setup Failed"
        case .deviceChangeFailed:
            "Device Change Failed"
        }
    }
    
    var errorDescription: String? { description }
}
