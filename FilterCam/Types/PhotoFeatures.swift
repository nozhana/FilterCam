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

protocol CameraOptionable: CaseIterable, Equatable, Identifiable {
    var title: String { get }
    var systemImage: String { get }
}

enum FlashMode: Int, Codable, CaseIterable, CameraOptionable {
    case off = 0, on, auto
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .off: String(localized: "Off")
        case .on: String(localized: "On")
        case .auto: String(localized: "Auto")
        }
    }
    
    var systemImage: String {
        switch self {
        case .off: "bolt.slash.fill"
        case .on: "bolt.fill"
        case .auto: "bolt.badge.automatic.fill"
        }
    }
}

enum QualityPrioritization: Int, Codable, CaseIterable, CameraOptionable {
    case speed = 1
    case balanced
    case quality
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .speed: String(localized: "Speed")
        case .balanced: String(localized: "Balanced")
        case .quality: String(localized: "Quality")
        }
    }
    
    var systemImage: String {
        switch self {
        case .speed: "bolt.horizontal.fill"
        case .balanced: "equal"
        case .quality: "sparkles"
        }
    }
}
