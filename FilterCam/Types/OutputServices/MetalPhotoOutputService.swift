//
//  MetalPhotoOutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import Combine
import Foundation

final class MetalPhotoOutputService: PhotoOutputService {
    @Published private(set) var captureActivity: CaptureActivity = .idle
    
    var captureActivityPublisher: AnyPublisher<CaptureActivity, Never> { $captureActivity.eraseToAnyPublisher() }
    
    private let photoOutput = MetalPhotoCaptureOutput()
    
    var output: some MetalCaptureOutput { photoOutput }
    
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
        let data = try await photoOutput.captureNextFrame()
        return Photo(data: data)
    }
}

extension PhotoOutputService where Self == MetalPhotoOutputService {
    static func metal() -> MetalPhotoOutputService {
        .init()
    }
}
