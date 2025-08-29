//
//  CaptureActivity.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

public enum CaptureActivity {
    case idle
    case photo(willCapture: Bool = false)
    case video(duration: TimeInterval = .zero)
}

public extension CaptureActivity {
    var willCapture: Bool {
        if case .photo(true) = self { return true }
        return false
    }
    
    var isRecording: Bool {
        if case .video = self { return true }
        return false
    }
    
    var duration: TimeInterval {
        if case .video(let duration) = self {
            return duration
        }
        return .zero
    }
}
