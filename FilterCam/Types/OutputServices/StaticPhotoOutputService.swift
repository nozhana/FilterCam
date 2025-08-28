//
//  StaticPhotoOutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/27/25.
//

import Combine
import Foundation

final class StaticPhotoOutputService: PhotoOutputService {
    var output: some CaptureOutput { .staticPhoto }
    
    private var staticPhotoOutput: StaticPhotoCaptureOutput {
        output as! StaticPhotoCaptureOutput
    }
    
    @Published private(set) var captureActivity = CaptureActivity.idle
    
    var captureActivityPublisher: AnyPublisher<CaptureActivity, Never> {
        $captureActivity.eraseToAnyPublisher()
    }
    
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
        captureActivity = .photo(willCapture: true)
        defer { captureActivity = .idle }
        guard let pngData = staticPhotoOutput.output.pngData() else {
            throw PhotoCaptureError.noPhotoData
        }
        return Photo(data: pngData)
    }
}

extension PhotoOutputService where Self == StaticPhotoOutputService {
    static var staticPhoto: StaticPhotoOutputService { .init() }
}
