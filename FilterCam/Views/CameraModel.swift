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
    
    // TODO: Pending more capture modes
    @Published var captureMode = CaptureMode.photo {
        didSet {
            cameraState.captureMode = captureMode
        }
    }
    @Published var flashMode = FlashMode.auto {
        didSet {
            cameraState.flashMode = flashMode
        }
    }
    @Published var qualityPrioritization = QualityPrioritization.balanced {
        didSet {
            cameraState.qualityPrioritization = qualityPrioritization
        }
    }
    
    let session = AVCaptureSession()
    private let captureService: CaptureService
    private var captureDirectory: URL!
    private var mediaStore: MediaStore!
    
    init() {
        captureService = .init(session: session)
    }
    
    // MARK: - Public
    func configure(with configuration: AppConfiguration) {
        captureDirectory = configuration.captureDirectory
        mediaStore = MediaStore(appConfiguration: configuration)
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
    }
    
    @MainActor
    func switchCamera() async {
        isSwitchingCameras = true
        defer { isSwitchingCameras = false }
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
            let photoURL = try mediaStore.savePhoto(photo)
            logger.debug("Photo saved to URL: \(String(describing: photoURL))")
        } catch {
            logger.error("Failed to capture photo: \(error)")
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
