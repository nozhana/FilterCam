//
//  CameraState.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

struct CameraState: Codable {
    enum CodingKeys: String, CodingKey {
        case captureMode
        case cameraPosition
        case qualityPrioritization
        case flashMode
    }
    
    init(from decoder: any Decoder) throws {
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
    }
    
    init(contextProvider: some ContextProvider) {
        self.contextProvider = contextProvider
    }
    
    private let contextProvider: ContextProvider
    
    var captureMode = CaptureMode.photo {
        didSet {
            if oldValue != captureMode {
                updateContext()
            }
        }
    }
    
    var cameraPosition = CameraPosition.back {
        didSet {
            if oldValue != cameraPosition {
                updateContext()
            }
        }
    }
    
    var qualityPrioritization = QualityPrioritization.balanced {
        didSet {
            if oldValue != qualityPrioritization {
                updateContext()
            }
        }
    }
    
    var flashMode = FlashMode.auto {
        didSet {
            if oldValue != flashMode {
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
    
    static var current: CameraState {
        get async {
            if #available(iOS 18.0, *) {
                return await .intent(FilterCamCaptureIntent.self)
            } else {
                return .idle
            }
        }
    }
}
