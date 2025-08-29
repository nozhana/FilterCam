//
//  MockCameraModel.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/27/25.
//

import FilterCamBase
import FilterCamShared
import Foundation
import GPUImage

final class MockCameraModel: CameraModelProtocol {
    @Published private(set) var cameraState: CameraState = .logging
    @Published private(set) var status: CameraStatus = .unknown
    @Published private(set) var isSwitchingCameras: Bool = false
    @Published private(set) var captureActivity: CaptureActivity = .idle
    @Published private(set) var shouldFlashScreen: Bool = false
    @Published private(set) var thumbnail: Thumbnail?
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var focusPoint: CGPoint?
    @Published private(set) var supportsUltraWideZoom: Bool = false
    @Published private(set) var supportsCustomExposure: Bool = false
    @Published private(set) var supportsCustomWhiteBalance: Bool = false
    @Published private(set) var activeDeviceExposure: Double = 0.5
    @Published private(set) var activeDeviceWhiteBalance: Double = 0.5
    
    @Published var zoomFactor: Double = 0.5
    @Published var exposure: Double?
    @Published var whiteBalance: Double?
    @Published var proRAW: Bool = false
    @Published var captureMode: CaptureMode = .photo
    @Published var flashMode: FlashMode = .firstAvailable
    @Published var qualityPrioritization: QualityPrioritization = .balanced
    @Published var aspectRatio: AspectRatio = .fourToThree
    @Published var renderMode: RenderMode = .default
    @Published var lastFilter: CameraFilter = .none
    @Published var showLevel: Bool = false
    
    private(set) var previewSource: any PreviewSource = .staticImage(.camPreview)
    
    private(set) var previewTarget: any PreviewTarget = .staticImage(.camPreview)
    
    private let photoOutput = StaticPhotoOutputService()
    
    private func observeState() {
        photoOutput.$captureActivity
            .receive(on: DispatchQueue.main)
            .assign(to: &$captureActivity)
    }
    
    func start() async {
        observeState()
        previewSource.connect(to: previewTarget)
        status = .running
    }
    
    func switchCaptureService(_ service: some CaptureService) async {
        if let imageSource = previewSource as? ImageSource {
            imageSource.removeAllTargets()
        }
        previewSource = service.previewSource
        previewTarget = service.previewTarget
        await start()
    }
    
    func capturePhoto() async {
        let features = PhotoFeatures(flashMode: cameraState.flashMode, qualityPrioritization: cameraState.qualityPrioritization)
        do {
            let photo = try await photoOutput.capturePhoto(with: features)
            let cropped = photo.cropped(to: aspectRatio.rawValue)
            logger.info("Mock model captured photo: \(String(describing: cropped))")
        } catch {
            logger.error("Failed to capture photo in mock model: \(error)\nPhoto features: \(String(describing: features))")
        }
    }
    
    func startRecording() async {
        logger.warning("Recording not implemented yet for mock model")
    }
    
    func stopRecording() async {
        logger.warning("Recording not implemented yet for mock model")
    }
    
    func focusAndExpose(on devicePoint: CGPoint, layerPoint: CGPoint) async {
        logger.warning("Focus and exposure not implemented yet for mock model")
    }
}
