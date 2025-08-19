//
//  PhotoFeatures.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

struct PhotoFeatures {
    var flashMode: FlashMode = .auto
    var qualityPrioritization: QualityPrioritization = .balanced
    
    static let `default` = PhotoFeatures()
}

enum FlashMode: Int, Codable {
    case off = 0, on, auto
}

enum QualityPrioritization: Int, Codable {
    case speed = 1
    case balanced
    case quality
}
