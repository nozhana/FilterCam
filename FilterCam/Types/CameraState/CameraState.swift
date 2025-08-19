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
        self.contextProvider = LoggingContextProvider()
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
        didSet { updateContext() }
    }
    
    var cameraPosition = CameraPosition.back {
        didSet { updateContext() }
    }
    
    var qualityPrioritization = QualityPrioritization.balanced {
        didSet { updateContext() }
    }
    
    var flashMode = FlashMode.auto {
        didSet { updateContext() }
    }
    
    private func updateContext() {
        // TODO: Update intent context
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
            // TODO: Get state from app context
            return .idle
        }
    }
}
