//
//  CameraModel.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import AVFoundation
import SwiftUI

final class CameraModel: ObservableObject {
    // MARK: - Properties
    @Published private(set) var cameraState: CameraState = .logging
    @Published private(set) var status: CameraStatus = .unknown
    @Published private(set) var isSwitchingCameras = false
    @Published private(set) var captureActivity: CaptureActivity = .idle
    @Published private(set) var shouldFlashScreen = false
    // @Published private(set) var thumbnail: CGImage?
    
    let session = AVCaptureSession()
    private let captureService: CaptureService
    private var captureDirectory: URL!
    
    init() {
        captureService = .init(session: session)
    }
    
    // MARK: - Public
    func configure(with configuration: AppConfiguration) {
        captureDirectory = configuration.captureDirectory
    }
    
    func start() async {
        guard await captureService.isAuthorized else {
            status = .unauthorized
            return
        }
        
        do {
            await syncState()
            try await captureService.start(with: cameraState)
            observeState()
            status = .running
        } catch {
            logger.error("Failed to start capture service: \(error)")
            status = .failed
        }
    }
    
    func syncState() async {
        let oldState = cameraState
        cameraState = await .current
        if oldState.captureMode != cameraState.captureMode {
            await captureService.setCaptureMode(cameraState.captureMode)
        }
    }
    
    func switchCamera() async {
        isSwitchingCameras = true
        defer { isSwitchingCameras = false }
        await captureService.switchCamera()
        cameraState.cameraPosition = await captureService.activeCameraPosition
    }
    
    func capturePhoto() async {
        do {
            let features = PhotoFeatures(flashMode: cameraState.flashMode, qualityPrioritization: cameraState.qualityPrioritization)
            let photo = try await captureService.capturePhoto(with: features)
            // TODO: Save to library
            logger.warning("CAPTURED PHOTO: \(String(describing: photo))")
        } catch {
            logger.error("Failed to capture photo: \(error)")
        }
    }
    
    // MARK: - Private
    private func observeState() {
        Task {
            for await activity in await captureService.$captureActivity.values {
                if activity.willCapture {
                    flashScreen()
                } else {
                    captureActivity = activity
                }
            }
        }
    }
    
    private func flashScreen() {
        shouldFlashScreen = true
        withAnimation(.linear(duration: 0.01)) {
            shouldFlashScreen = false
        }
    }
}
