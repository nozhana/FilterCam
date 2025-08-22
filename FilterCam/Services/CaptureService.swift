//
//  CaptureService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Combine
import Foundation

final actor CaptureService {
    @Published private(set) var captureActivity: CaptureActivity = .idle
    @Published private(set) var isInterrupted = false
    
    nonisolated let previewSource: PreviewSource
    
    private let session: AVCaptureSession
    
    private let photoOutput = PhotoOutput()
    
    private let movieOutput = MovieOutput()
    
    private var outputServices: [any OutputService] { [photoOutput, movieOutput] }
    
    private var activeVideoInput: AVCaptureDeviceInput?
    
    private(set) var captureMode = CaptureMode.photo
    
    private let deviceLookup = DeviceLookup()
    
    private let systemPreferredCamera = SystemPreferredCameraObserver()
    
    // private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    // private var rotationObservers: [AnyObject] = []
    
    private var isSetUp = false
    
    private let sessionQueue = DispatchSerialQueue(label: "com.nozhana.FilterCam.sessionQueue")
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    init(session: AVCaptureSession? = nil) {
        self.session = session ?? .init()
        previewSource = .default(session: self.session)
    }
    
    var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            return isAuthorized
        }
    }
    
    var activeCameraPosition: CameraPosition {
        .init(rawValue: currentDevice.position.rawValue) ?? .unspecified
    }
    
    private var currentDevice: AVCaptureDevice {
        guard let device = activeVideoInput?.device else {
            fatalError("No device found for current video input.")
        }
        return device
    }
    
    func start(with state: CameraState) async throws {
        captureMode = state.captureMode
        try setUpSession()
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    func startSession() {
        session.startRunning()
    }
    
    func setUpSession() throws {
        guard !isSetUp else { return }
        
        observeOutputServices()
        observeNotifications()
        
        do {
            let defaultCamera = try deviceLookup.defaultCamera
            let defaultMic = try deviceLookup.defaultMic
            
            activeVideoInput = try addInput(for: defaultCamera)
            try addInput(for: defaultMic)
            
            session.sessionPreset = captureMode == .photo ? .photo : .high
            try addOutput(photoOutput.output)
            
            monitorSystemPreferredCamera()
            updateOutputConfigurations()
        } catch {
            throw CameraError.setupFailed
        }
    }
    
    func setCaptureMode(_ captureMode: CaptureMode) {
        session.sessionPreset = captureMode == .photo ? .photo : .high
        self.captureMode = captureMode
        switch captureMode {
        case .photo:
            if session.outputs.contains(movieOutput.output) {
                session.removeOutput(movieOutput.output)
            }
        case .video:
            do {
                try addOutput(movieOutput.output)
            } catch {
                logger.error("Failed to add movie output to session.")
            }
        }
    }
    
    func switchCamera() {
        let videoDevices = deviceLookup.cameras
        let selectedIndex = videoDevices.firstIndex(of: currentDevice) ?? 0
        var nextIndex = selectedIndex + 1
        if nextIndex == videoDevices.endIndex {
            nextIndex = 0
        }
        
        let nextDevice = videoDevices[nextIndex]
        
        changeCaptureDevice(to: nextDevice)
        
        AVCaptureDevice.userPreferredCamera = nextDevice
    }
    
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo {
        try await photoOutput.capturePhoto(with: features)
    }
    
    func recordVideo(with features: VideoFeatures) async throws -> Video {
        try await movieOutput.recordVideo(with: features)
    }
    
    func stopRecording() {
        movieOutput.stopRecording()
    }
    
    func focusAndExpose(on devicePoint: CGPoint) throws {
        try currentDevice.lockForConfiguration()
        defer { currentDevice.unlockForConfiguration() }
        if currentDevice.isFocusPointOfInterestSupported {
            currentDevice.focusPointOfInterest = devicePoint
        }
        if currentDevice.isFocusModeSupported(.continuousAutoFocus) {
            currentDevice.focusMode = .continuousAutoFocus
        }
        if currentDevice.isExposurePointOfInterestSupported {
            currentDevice.exposurePointOfInterest = devicePoint
        }
        if currentDevice.isExposureModeSupported(.continuousAutoExposure) {
            currentDevice.exposureMode = .continuousAutoExposure
        }
    }
    
    private func observeOutputServices() {
        photoOutput.$captureActivity
            .merge(with: movieOutput.$captureActivity)
            .assign(to: &$captureActivity)
    }
    
    private func observeNotifications() {
        Task {
            for await reason in NotificationCenter.default.notifications(named: AVCaptureSession.wasInterruptedNotification)
                .compactMap({ $0.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject? })
                .compactMap({ AVCaptureSession.InterruptionReason(rawValue: $0.integerValue) }) {
                isInterrupted = [.audioDeviceInUseByAnotherClient, .videoDeviceInUseByAnotherClient].contains(reason)
            }
        }
        
        Task {
            for await _ in NotificationCenter.default.notifications(named: AVCaptureSession.interruptionEndedNotification) {
                isInterrupted = false
            }
        }
        
        Task {
            for await error in NotificationCenter.default.notifications(named: AVCaptureSession.runtimeErrorNotification)
                .compactMap({ $0.userInfo?[AVCaptureSessionErrorKey] as? AVError }) {
                if error.code == .mediaServicesWereReset {
                    if !session.isRunning {
                        session.startRunning()
                    }
                }
            }
        }
    }
    
    @discardableResult
    private func addInput(for device: AVCaptureDevice) throws -> AVCaptureDeviceInput {
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            throw CameraError.addInputFailed
        }
        return input
    }
    
    private func addOutput(_ output: AVCaptureOutput) throws {
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            throw CameraError.addOutputFailed
        }
    }
    
    private func monitorSystemPreferredCamera() {
        Task {
            for await camera in systemPreferredCamera.changes {
                if let camera, currentDevice != camera {
                    logger.debug("Switching camera to system preferred camera")
                    changeCaptureDevice(to: camera)
                }
            }
        }
    }
    
    private func changeCaptureDevice(to device: AVCaptureDevice) {
        guard let currentInput = activeVideoInput else { fatalError("No active video input device found") }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.removeInput(currentInput)
        do {
            activeVideoInput = try addInput(for: device)
            updateOutputConfigurations()
        } catch {
            session.addInput(currentInput)
        }
    }
    
    private func updateOutputConfigurations() {
        outputServices.forEach { $0.updateConfiguration(for: currentDevice) }
    }
}
