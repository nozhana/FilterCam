//
//  PhotoFeatures.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Foundation
import CoreGraphics

struct PhotoFeatures {
    var flashMode: FlashMode = .firstAvailable
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
    
    static var availableFlashModes: [FlashMode] {
        if let systemPreferredCamera = AVCaptureDevice.systemPreferredCamera,
           systemPreferredCamera.hasFlash,
           systemPreferredCamera.isFlashAvailable {
            return FlashMode.allCases
        }
        return [.off]
    }
    
    static let firstAvailable = availableFlashModes.first!
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

enum AspectRatio: CGFloat, Codable, CaseIterable, CameraOptionable {
    case fourToThree
    case sixteenToNine
    case threeToTwo
    
    var id: CGFloat { rawValue }
    
    var rawValue: CGFloat {
        switch self {
        case .fourToThree: 4.0/3
        case .sixteenToNine: 16.0/9
        case .threeToTwo: 3.0/2
        }
    }
    
    init?(rawValue: CGFloat) {
        if let value: AspectRatio = switch rawValue {
        case 4.0/3: .fourToThree
        case 16.0/9: .sixteenToNine
        case 3.0/2: .threeToTwo
        default: nil
        } {
            self = value
        } else {
            return nil
        }
    }
    
    var title: String {
        switch self {
        case .fourToThree: "4:3"
        case .sixteenToNine: "16:9"
        case .threeToTwo: "3:2"
        }
    }
    
    var systemImage: String {
        "aspectratio"
    }
    
    var previewOffsetY: CGFloat {
        switch self {
        case .fourToThree: 110
        case .threeToTwo: 60
        case .sixteenToNine: .zero
        }
    }
}
