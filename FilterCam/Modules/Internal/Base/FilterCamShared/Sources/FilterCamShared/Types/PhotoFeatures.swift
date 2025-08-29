//
//  PhotoFeatures.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Foundation
import CoreGraphics

public struct PhotoFeatures {
    public var flashMode: FlashMode = .firstAvailable
    public var qualityPrioritization: QualityPrioritization = .balanced
    
    public init(flashMode: FlashMode = .firstAvailable, qualityPrioritization: QualityPrioritization = .balanced) {
        self.flashMode = flashMode
        self.qualityPrioritization = qualityPrioritization
    }
    
    public static let `default` = PhotoFeatures()
}

public protocol CameraOptionable: Equatable, Identifiable {
    var title: String { get }
    var systemImage: String { get }
}

public enum FlashMode: Int, Codable, CaseIterable, CameraOptionable {
    case off = 0, on, auto
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .off: String(localized: "Off")
        case .on: String(localized: "On")
        case .auto: String(localized: "Auto")
        }
    }
    
    public var systemImage: String {
        switch self {
        case .off: "bolt.slash.fill"
        case .on: "bolt.fill"
        case .auto: "bolt.badge.automatic.fill"
        }
    }
    
    public static var availableFlashModes: [FlashMode] {
        if let systemPreferredCamera = AVCaptureDevice.systemPreferredCamera,
           systemPreferredCamera.hasFlash,
           systemPreferredCamera.isFlashAvailable {
            return FlashMode.allCases
        }
        return [.off]
    }
    
    public static let firstAvailable = availableFlashModes.first!
}

public enum QualityPrioritization: Int, Codable, CaseIterable, CameraOptionable {
    case speed = 1
    case balanced
    case quality
    
    public var id: Int { rawValue }
    
    public var title: String {
        switch self {
        case .speed: String(localized: "Speed")
        case .balanced: String(localized: "Balanced")
        case .quality: String(localized: "Quality")
        }
    }
    
    public var systemImage: String {
        switch self {
        case .speed: "bolt.horizontal.fill"
        case .balanced: "equal"
        case .quality: "sparkles"
        }
    }
}

public enum AspectRatio: CGFloat, Codable, CaseIterable, CameraOptionable {
    case fourToThree
    case sixteenToNine
    case threeToTwo
    case square
    
    public var id: CGFloat { rawValue }
    
    public var rawValue: CGFloat {
        switch self {
        case .fourToThree: 4.0/3
        case .sixteenToNine: 16.0/9
        case .threeToTwo: 3.0/2
        case .square: 1.0
        }
    }
    
    public init?(rawValue: CGFloat) {
        if let value: AspectRatio = switch rawValue {
        case 4.0/3: .fourToThree
        case 16.0/9: .sixteenToNine
        case 3.0/2: .threeToTwo
        case 1.0: .square
        default: nil
        } {
            self = value
        } else {
            return nil
        }
    }
    
    public var title: String {
        switch self {
        case .fourToThree: "4:3"
        case .sixteenToNine: "16:9"
        case .threeToTwo: "3:2"
        case .square: "Square"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .fourToThree: "rectangle.ratio.3.to.4"
        case .sixteenToNine: "rectangle.ratio.9.to.16"
        case .threeToTwo: "aspectratio"
        case .square: "square"
        }
    }
    
    public var previewOffsetY: CGFloat {
        switch self {
        case .fourToThree: 110
        case .threeToTwo: 60
        case .sixteenToNine: .zero
        case .square: 140
        }
    }
}
