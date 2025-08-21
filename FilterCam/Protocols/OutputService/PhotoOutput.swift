//
//  PhotoOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Foundation

final class PhotoOutput: OutputService {
    private let photoOutput = AVCapturePhotoOutput()
    
    var output: AVCapturePhotoOutput { photoOutput }
    @Published private(set) var captureActivity: CaptureActivity = .idle
    
    func updateConfiguration(for device: AVCaptureDevice) {
        photoOutput.maxPhotoDimensions = device.activeFormat.supportedMaxPhotoDimensions.last ?? .zero
        photoOutput.maxPhotoQualityPrioritization = .quality
        photoOutput.isResponsiveCaptureEnabled = photoOutput.isResponsiveCaptureSupported
        photoOutput.isFastCapturePrioritizationEnabled = photoOutput.isFastCapturePrioritizationSupported
        photoOutput.isAutoDeferredPhotoDeliveryEnabled = photoOutput.isAutoDeferredPhotoDeliverySupported
    }
    
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
        try await withCheckedThrowingContinuation { continuation in
            let settings = createPhotoSettings(with: features)
            let delegate = PhotoCaptureDelegate(continuation: continuation)
            monitorProgress(of: delegate)
            photoOutput.capturePhoto(with: settings, delegate: delegate)
        }
    }
    
    private func createPhotoSettings(with features: PhotoFeatures) -> AVCapturePhotoSettings {
        var settings = AVCapturePhotoSettings()
        
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            settings = .init(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        if let previewPixelFormatType = settings.availablePreviewPhotoPixelFormatTypes.first {
            settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelFormatType]
        }
        
        settings.maxPhotoDimensions = photoOutput.maxPhotoDimensions
        
        if let flashMode = AVCaptureDevice.FlashMode(rawValue: features.flashMode.rawValue) {
            settings.flashMode = flashMode
        }
        
        if let prioritization = AVCapturePhotoOutput.QualityPrioritization(rawValue: features.qualityPrioritization.rawValue) {
            settings.photoQualityPrioritization = prioritization
        }
        
        logger.debug("AVCapturePhotoSettings: \(settings)")
        
        return settings
    }
    
    private func monitorProgress(of delegate: PhotoCaptureDelegate, isolation: (any Actor)? = #isolation) {
        Task {
            _ = isolation
            for await activity in delegate.activityStream {
                captureActivity = activity
            }
        }
    }
}

typealias PhotoContinuation = CheckedContinuation<Photo, Error>
typealias ActivityStream = AsyncStream<CaptureActivity>

final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let continuation: PhotoContinuation
    
    private var photoData: Data?
    private var isProxyPhoto = false
    
    let activityStream: ActivityStream
    private let activityContinuation: ActivityStream.Continuation
    
    init(continuation: PhotoContinuation) {
        self.continuation = continuation
        (activityStream, activityContinuation) = AsyncStream.makeStream()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        activityContinuation.yield(.photo(willCapture: true))
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: (any Error)?) {
        if let error {
            logger.error("Error capturing deferred photo: \(error)")
        }
        
        photoData = deferredPhotoProxy?.fileDataRepresentation()
        isProxyPhoto = true
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let error {
            logger.error("Error capturing photo: \(error)")
        }
        
        photoData = photo.fileDataRepresentation()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
        defer {
            activityContinuation.finish()
        }
        
        if let error {
            continuation.resume(throwing: error)
            return
        }
        
        guard let photoData else {
            continuation.resume(throwing: PhotoCaptureError.noPhotoData)
            return
        }
        
        let photo = Photo(data: photoData, isProxy: isProxyPhoto)
        continuation.resume(returning: photo)
    }
}
