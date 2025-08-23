//
//  CameraModel.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import AVFoundation
import Combine
import SwiftUI

final class CameraModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var cameraState: CameraState = .logging
    @Published private(set) var status: CameraStatus = .unknown
    @Published private(set) var isSwitchingCameras = false
    @Published private(set) var captureActivity: CaptureActivity = .idle
    @Published private(set) var shouldFlashScreen = false
    @Published private(set) var thumbnail: Thumbnail?
    @Published private(set) var isPaused = false
    @Published private(set) var focusPoint: CGPoint?
    @Published private(set) var toastText: Text?
    
    // TODO: Pending more capture modes
    @Published var captureMode = CaptureMode.photo {
        didSet {
            cameraState.captureMode = captureMode
            Task { await captureService.setCaptureMode(captureMode) }
        }
    }
    @Published var flashMode = FlashMode.firstAvailable {
        didSet {
            cameraState.flashMode = flashMode
        }
    }
    @Published var qualityPrioritization = QualityPrioritization.balanced {
        didSet {
            cameraState.qualityPrioritization = qualityPrioritization
        }
    }
    @Published var aspectRatio = AspectRatio.fourToThree {
        didSet {
            cameraState.aspectRatio = aspectRatio
        }
    }
    
    private var captureService = try! CaptureService.default()
    private var captureDirectory: URL!
    private var mediaStore: MediaStore!
    
    var previewTarget: any PreviewTarget {
        captureService.previewTarget
    }
    
    // MARK: - Public
    func configure(with configuration: AppConfiguration) {
        captureDirectory = configuration.captureDirectory
        mediaStore = MediaStore(appConfiguration: configuration)
        let useMetalRendering = UserDefaults.shared.bool(forKey: UserDefaultsKey.useMetalRendering.rawValue)
        captureService = useMetalRendering ? try! .metal() : try! .default()
    }
    
    func showToast(_ text: Text) {
        withAnimation(.bouncy) {
            toastText = text
        } completion: {
            withAnimation(.smooth(duration: 1).delay(3)) {
                self.toastText = nil
            }
        }
    }
    
    @MainActor
    func start() async {
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        
        do {
            await syncState()
            try await captureService.start(with: cameraState)
            observeState()
            mediaStore.refreshThumbnail()
            status = .running
        } catch {
            logger.error("Failed to start capture service: \(error)")
            status = .failed
        }
    }
    
    func switchCaptureService(_ service: some CaptureService) async {
        let oldService = captureService
        await captureService.stopSession()
        captureService = service
        do {
            try await captureService.start(with: cameraState)
        } catch {
            logger.error("Failed to switch capture service: \(error)")
            captureService = oldService
            await captureService.startSession()
        }
    }
    
    @MainActor
    func pauseStream() async {
        guard status == .running else { return }
        await captureService.stopSession()
        withAnimation(.smooth) {
            isPaused = true
        }
    }
    
    @MainActor
    func unpauseStream() async {
        guard status == .running else { return }
        await captureService.startSession()
        observeState()
        mediaStore.refreshThumbnail()
        withAnimation(.smooth) {
            isPaused = false
        }
    }
    
    @MainActor
    func syncState() async {
        let oldState = cameraState
        cameraState = await .current
        if oldState.captureMode != cameraState.captureMode {
            await captureService.setCaptureMode(cameraState.captureMode)
        }
        captureMode = cameraState.captureMode
        flashMode = cameraState.flashMode
        qualityPrioritization = cameraState.qualityPrioritization
        aspectRatio = cameraState.aspectRatio
    }
    
    @MainActor
    func switchCamera() async {
        if captureService.previewSource is MetalCameraSource {
            logger.warning("Metal camera doesn't support switching yet.")
            showToast(Text("Metal front camera isn't supported yet."))
            return
        }
        withAnimation(.snappy) {
            isSwitchingCameras = true
        }
        defer {
            withAnimation(.snappy) {
                isSwitchingCameras = false
            }
        }
        await captureService.switchCamera()
        cameraState.cameraPosition = await captureService.activeCameraPosition
    }
    
    func capturePhoto() async {
        do {
            logger.debug("-- CAPTURING PHOTO --")
            let features = PhotoFeatures(flashMode: cameraState.flashMode, qualityPrioritization: cameraState.qualityPrioritization)
            logger.debug("Features: \(String(describing: features))")
            let photo = try await captureService.capturePhoto(with: features)
            logger.debug("Captured photo: \(String(describing: photo))")
            let croppedPhoto = photo.cropped(to: aspectRatio.rawValue)
            logger.debug("Cropped photo: \(String(describing: croppedPhoto))")
            let photoURL = try mediaStore.savePhoto(croppedPhoto)
            logger.debug("Photo saved to URL: \(String(describing: photoURL))")
        } catch {
            logger.error("Failed to capture photo: \(error)")
        }
    }
    
    func startRecording() async {
        do {
            logger.debug("-- RECORDING VIDEO --")
            let features = VideoFeatures(flashMode: cameraState.flashMode)
            logger.debug("Features: \(String(describing: features))")
            let video = try await captureService.recordVideo(with: features)
            logger.debug("Recorded video: \(String(describing: video))")
            let videoURL = try mediaStore.saveVideo(video)
            logger.debug("Video saved to URL: \(String(describing: videoURL))")
        } catch {
            logger.error("Failed to record video: \(error)")
        }
    }
    
    func stopRecording() async {
        await captureService.stopRecording()
    }
    
    @MainActor
    private func flashFocusTarget(on layerPoint: CGPoint) {
        focusPoint = layerPoint
        withAnimation(.snappy.delay(3)) {
            focusPoint = nil
        }
    }
    
    func focusAndExpose(on devicePoint: CGPoint, layerPoint: CGPoint) async {
        do {
            try await captureService.focusAndExpose(on: devicePoint)
            await flashFocusTarget(on: layerPoint)
        } catch {
            logger.error("Failed to auto-focus-and-expose on devicePoint: \(String(describing: devicePoint))")
        }
    }
    
    // MARK: - Private
    private func observeState() {
        Task {
            for await activity in await captureService.$captureActivity.values {
                if activity.willCapture {
                    await flashScreen()
                } else {
                    await MainActor.run {
                        captureActivity = activity
                    }
                }
            }
        }
        
        Task {
            for await thumbnail in mediaStore.thumbnailStream {
                await MainActor.run {
                    withAnimation(.snappy) {
                        self.thumbnail = thumbnail
                    }
                }
            }
        }
    }
    
    @MainActor
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.01)) {
            shouldFlashScreen = false
        }
    }
}
