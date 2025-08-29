//
//  CameraStatus.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import Foundation

public enum CameraStatus: Int, CustomStringConvertible {
    case unknown, failed, unauthorized, loading, running, interrupted
    
    public var description: String {
        switch self {
        case .unknown:
            "Unknown"
        case .failed:
            "Failed"
        case .unauthorized:
            "Unauthorized"
        case .running:
            "Running"
        case .loading:
            "Loading"
        case .interrupted:
            "Interrupted"
        }
    }
}
