//
//  MetalPhotoCaptureOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import GPUImage
import UIKit

struct MetalPhotoCaptureOutput: MetalCaptureOutput {
    let output: PictureOutput
    
    init() {
        output = .init()
        output.onlyCaptureNextFrame = true
    }
    
    func captureNextFrame(format: PictureFileFormat = .png) async throws -> Data {
        output.onlyCaptureNextFrame = true
        let previousFormat = output.encodedImageFormat
        output.encodedImageFormat = format
        return try await withCheckedThrowingContinuation { continuation in
            output.imageAvailableCallback = { image in
                defer { output.imageAvailableCallback = nil }
                guard let data = image.pngData() else {
                    continuation.resume(throwing: PhotoCaptureError.noPhotoData)
                    return
                }
                continuation.resume(returning: data)
                output.encodedImageFormat = previousFormat
            }
        }
    }
    
    func saveNextFrame(to url: URL) {
        output.saveNextFrameToURL(url, format: .png)
    }
}
