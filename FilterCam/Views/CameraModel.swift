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
    @Published private(set) var supportsUltraWideZoom = false
    @Published private(set) var supportsCustomExposure = false
    @Published private(set) var supportsCustomWhiteBalance = false
    @Published private(set) var activeDeviceExposure = 0.5
    @Published private(set) var activeDeviceWhiteBalance: Double = 4000
    
    var isRunningAndActive: Bool {
        status == .running && !isPaused && !isSwitchingCameras
    }
    
    @Published var zoomFactor: Double = 1.0 {
        didSet {
            Task {
                await captureService.zoom(to: zoomFactor)
            }
        }
    }
    
    @Published var exposure: Double? {
        didSet {
            Task {
                await captureService.setExposure(to: exposure.map { CGFloat($0) })
            }
        }
    }
    
    @Published var whiteBalance: Double? {
        didSet {
            Task {
                await captureService.setWhiteBalance(to: whiteBalance.map { Float($0) })
            }
        }
    }
    
    @Published var proRAW = false {
        didSet {
            Task {
                // TODO: Set Pro RAW on capture service
            }
        }
    }
    
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
    @Published var renderMode = RenderMode.default {
        didSet {
            cameraState.renderMode = renderMode
        }
    }
    @Published var lastFilter = CameraFilter.none {
        didSet {
            cameraState.lastFilter = lastFilter
        }
    }
    @Published var showLevel = false {
        didSet {
            cameraState.showLevel = showLevel
        }
    }
    
    private var captureService = CaptureService.default()
    private var captureDirectory: URL!
    private var mediaStore: MediaStore!
    
    var previewSource: any PreviewSource {
        captureService.previewSource
    }
    
    var previewTarget: any PreviewTarget {
        captureService.previewTarget
    }
    
    // MARK: - Public
    func configure(with configuration: AppConfiguration) async {
        captureDirectory = configuration.captureDirectory
        mediaStore = MediaStore(appConfiguration: configuration)
    }
    
    @MainActor
    func start() async {
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        
        status = .loading
        
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
        await oldService.tearDownSession()
        await service.tearDownSession()
        captureService = service
        do {
            try await captureService.start(with: cameraState)
            zoomFactor = 1
        } catch {
            logger.error("Failed to switch capture service: \(error)")
            captureService = oldService
            do {
                try await captureService.start(with: cameraState)
            } catch {
                logger.error("Failed to restart previous capture service: \(error)")
                status = .failed
            }
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
        status = .loading
        defer { status = .running }
        await captureService.startSession()
        observeState()
        mediaStore.refreshThumbnail()
        withAnimation(.smooth) {
            isPaused = false
        }
    }
    
    @MainActor
    private func syncState() async {
        let oldState = cameraState
        cameraState = await .current
        if oldState.captureMode != cameraState.captureMode {
            await captureService.setCaptureMode(cameraState.captureMode)
        }
        switch cameraState.renderMode {
        case .default:
            await switchCaptureService(.default())
        case .metal:
            do {
                await switchCaptureService(try .metal())
            } catch {
                logger.error("Failed to switch capture service")
            }
        case .metalWithFilters:
            do {
                await switchCaptureService(try .metalWithFilters())
            } catch {
                logger.error("Failed to switch capture service")
            }
        }
        captureMode = cameraState.captureMode
        flashMode = cameraState.flashMode
        qualityPrioritization = cameraState.qualityPrioritization
        aspectRatio = cameraState.aspectRatio
        renderMode = cameraState.renderMode
        lastFilter = cameraState.lastFilter
        showLevel = cameraState.showLevel
    }
    
    @MainActor
    func switchCamera() async {
        if captureService.previewSource is MetalCameraSource {
            logger.warning("Metal camera doesn't support switching yet.")
            Toaster.shared.showToast(.warning(Text("Metal front camera isn't supported yet.")))
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
        zoomFactor = 1
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
        
        Task {
            await captureService.$supportsUltraWideZoom
                .receive(on: DispatchQueue.main)
                .assign(to: &$supportsUltraWideZoom)
            await captureService.$supportsCustomExposure
                .receive(on: DispatchQueue.main)
                .assign(to: &$supportsCustomExposure)
            await captureService.$supportsCustomWhiteBalance
                .receive(on: DispatchQueue.main)
                .assign(to: &$supportsCustomWhiteBalance)
        }
        
        Task {
            await captureService.$activeDeviceExposure
                .receive(on: DispatchQueue.main)
                .assign(to: &$activeDeviceExposure)
        }
        
        Task {
            await captureService.$activeDeviceWhiteBalanceTemperature
                .receive(on: DispatchQueue.main)
                .assign(to: &$activeDeviceWhiteBalance)
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
