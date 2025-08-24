//
//  VideoRecordingError.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import Foundation

enum VideoRecordingError: LocalizedError, CustomStringConvertible {
    case noVideoData
    
    var description: String {
        switch self {
        case .noVideoData: "No Video Data"
        }
    }
    
    var errorDescription: String? { description }
}
