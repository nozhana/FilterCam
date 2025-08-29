//
//  CameraState.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

public struct CameraState: Codable {
    public enum CodingKeys: String, CodingKey {
        case captureMode
        case cameraPosition
        case qualityPrioritization
        case flashMode
        case aspectRatio
        case renderMode
        case lastFilter
        case showLevel
    }
    
    public init(from decoder: any Decoder) throws {
        if #available(iOS 18.0, *) {
            self.contextProvider = .intent(FilterCamCaptureIntent.self).chain(to: .logging)
        } else {
            self.contextProvider = .logging
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        captureMode = try container.decode(CaptureMode.self, forKey: .captureMode)
        cameraPosition = try container.decode(CameraPosition.self, forKey: .cameraPosition)
        qualityPrioritization = try container.decode(QualityPrioritization.self, forKey: .qualityPrioritization)
        flashMode = try container.decode(FlashMode.self, forKey: .flashMode)
        aspectRatio = try container.decode(AspectRatio.self, forKey: .aspectRatio)
        renderMode = try container.decode(RenderMode.self, forKey: .renderMode)
        lastFilter = try container.decode(CameraFilter.self, forKey: .lastFilter)
        showLevel = try container.decode(Bool.self, forKey: .showLevel)
    }
    
    public init(contextProvider: some ContextProvider) {
        self.contextProvider = contextProvider
    }
    
    private let contextProvider: ContextProvider
    
    public var captureMode = CaptureMode.photo {
        didSet {
            if oldValue != captureMode {
                updateContext()
            }
        }
    }
    
    public var cameraPosition = CameraPosition.back {
        didSet {
            if oldValue != cameraPosition {
                updateContext()
            }
        }
    }
    
    public var qualityPrioritization = QualityPrioritization.balanced {
        didSet {
            if oldValue != qualityPrioritization {
                updateContext()
            }
        }
    }
    
    public var flashMode = FlashMode.firstAvailable {
        didSet {
            if oldValue != flashMode {
                updateContext()
            }
        }
    }
    
    public var aspectRatio = AspectRatio.fourToThree {
        didSet {
            if oldValue != aspectRatio {
                updateContext()
            }
        }
    }
    
    public var renderMode = RenderMode.default {
        didSet {
            if oldValue != renderMode {
                updateContext()
            }
        }
    }
    
    public var lastFilter = CameraFilter.none {
        didSet {
            if oldValue != lastFilter {
                updateContext()
            }
        }
    }
    
    public var showLevel = false {
        didSet {
            if oldValue != showLevel {
                updateContext()
            }
        }
    }
    
    private func updateContext() {
        Task {
            do {
                try await contextProvider.update(with: self)
            } catch {
                logger.error("Failed to update app context: \(error)")
            }
        }
    }
    
    public static var current: CameraState {
        get async {
            if #available(iOS 18.0, *) {
                return await .intent(FilterCamCaptureIntent.self)
            } else {
                return .idle
            }
        }
    }
    
    public static func update<T>(_ keyPath: WritableKeyPath<CameraState, T>, with newValue: T) async {
        var current = await current
        current[keyPath: keyPath] = newValue
    }
}
