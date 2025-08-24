//
//  CaptureService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Combine
import Foundation
import GPUImage

final actor CaptureService {
    @Published private(set) var captureActivity: CaptureActivity = .idle
    @Published private(set) var isInterrupted = false
    
    nonisolated let previewSource: PreviewSource
    
    nonisolated let previewTarget: PreviewTarget
    
    nonisolated let photoOutput: any PhotoOutputService
    
    nonisolated let movieOutput: any MovieOutputService
    
    private let session: AVCaptureSession
    
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
    
    private init(previewSource: some PreviewSource, previewTarget: some PreviewTarget, photoOutput: any PhotoOutputService, movieOutput: any MovieOutputService, session: AVCaptureSession) {
        self.previewSource = previewSource
        self.previewTarget = previewTarget
        self.photoOutput = photoOutput
        self.movieOutput = movieOutput
        self.session = session
    }
    
    static func `default`() -> CaptureService {
        let session = AVCaptureSession()
#if DEBUG
        if ProcessInfo.isRunningPreviews || UserDefaults.shared.bool(forKey: UserDefaultsKey.mockCamera.rawValue) {
            return CaptureService(previewSource: .staticImage(.camPreview), previewTarget: .staticImage(.camPreview), photoOutput: .default(), movieOutput: .default(), session: session)
        } else {
            return CaptureService(previewSource: .default(session: session), previewTarget: .default(), photoOutput: .default(), movieOutput: .default(), session: session)
        }
#else
        return CaptureService(previewSource: .default(session: session), previewTarget: .default(), photoOutput: .default(), movieOutput: .default(), session: session)
#endif
    }
    
    static func metal() throws -> CaptureService {
#if DEBUG
        if ProcessInfo.isRunningPreviews || UserDefaults.shared.bool(forKey: UserDefaultsKey.mockCamera.rawValue) {
            return CaptureService(previewSource: .staticImage(.camPreview), previewTarget: .metal(), photoOutput: .metal(), movieOutput: .metal(), session: .init())
        } else {
            let metalCamera = try MetalCameraSource()
            let session = metalCamera.session
            return CaptureService(previewSource: metalCamera, previewTarget: .metal(), photoOutput: .metal(), movieOutput: .metal(), session: session)
        }
#else
        let metalCamera = try MetalCameraSource()
        let session = metalCamera.session
        return CaptureService(previewSource: metalCamera, previewTarget: .metal(), photoOutput: .metal(), movieOutput: .metal(), session: session)
#endif
    }
    
    static func metalWithFilters() throws -> CaptureService {
        let filterStack: FilterStack = [.none, .haze(), .noir, .sepia(), .blur(), .lookup(image: .agfaVista), .lookup(image: .moodyFilm), .lookup(image: .portra800), .lookup(image: .classicChrome), .lookup(image: .eliteChrome), .lookup(image: .polaroidColor), .lookup(image: .velvia100)]
#if DEBUG
        if ProcessInfo.isRunningPreviews || UserDefaults.shared.bool(forKey: UserDefaultsKey.mockCamera.rawValue) {
            return CaptureService(previewSource: .staticImage(.camPreview), previewTarget: filterStack, photoOutput: .metal(), movieOutput: .metal(), session: .init())
        } else {
            let metalCamera = try MetalCameraSource()
            let session = metalCamera.session
            return CaptureService(previewSource: metalCamera, previewTarget: filterStack, photoOutput: .metal(), movieOutput: .metal(), session: session)
        }
#else
        let metalCamera = try MetalCameraSource()
        let session = metalCamera.session
        return CaptureService(previewSource: metalCamera, previewTarget: filterStack, photoOutput: .metal(), movieOutput: .metal(), session: session)
#endif
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
        guard !isSetUp, !session.isRunning else { return }
        captureMode = state.captureMode
        configurePipeline()
        try await setUpSession()
        if let camera = previewSource as? MetalCameraSource {
            logger.debug("Starting metal camera")
            camera.start()
        } else {
            logger.debug("Starting basic camera")
            session.startRunning()
        }
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    func startSession() {
        session.startRunning()
    }
    
    func tearDownSession() {
        session.stopRunning()
        guard isSetUp else { return }
        defer { isSetUp = false }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        for input in session.inputs {
            session.removeInput(input)
        }
        
        for output in session.outputs {
            session.removeOutput(output)
        }
        
        let preset: AVCaptureSession.Preset = captureMode == .photo ? .photo : .high
        if session.canSetSessionPreset(preset) {
            session.sessionPreset = preset
        }
    }
    
    private func setUpSession() async throws {
        guard !isSetUp else { return }
        
        observeOutputServices()
        observeNotifications()
        
        do {
            let defaultCamera: AVCaptureDevice
            if let cameraSource = previewSource as? MetalCameraSource {
                defaultCamera = cameraSource.camera.inputCamera
                activeVideoInput = try AVCaptureDeviceInput(device: defaultCamera)
            } else {
                defaultCamera = try deviceLookup.defaultCamera
                activeVideoInput = try addInput(for: defaultCamera)
            }
            let defaultMic = try deviceLookup.defaultMic
            try addInput(for: defaultMic)
            
            session.sessionPreset = captureMode == .photo ? .photo : .high
            if let defaultOutput = photoOutput.output as? any DefaultCaptureOutput {
                try addOutput(defaultOutput.output)
            } else if let metalOutput = photoOutput.output as? any MetalCaptureOutput,
                      let metalCamera = previewSource as? MetalCameraSource {
                let currentState = await CameraState.current
                if currentState.renderMode == .metalWithFilters {
                    let operation = currentState.lastFilter.makeOperation()
                    operation.addTarget(metalOutput.output, atTargetIndex: 0)
                    metalCamera --> operation
                } else {
                    metalCamera --> metalOutput.output
                }
            }
            
            monitorSystemPreferredCamera()
            updateOutputConfigurations()
            isSetUp = true
        } catch {
            throw CameraError.setupFailed
        }
    }
    
    func setCaptureMode(_ captureMode: CaptureMode) {
        session.sessionPreset = captureMode == .photo ? .photo : .high
        self.captureMode = captureMode
        guard let defaultOutput = movieOutput.output as? any DefaultCaptureOutput else { return }
        switch captureMode {
        case .photo:
            if session.outputs.contains(defaultOutput.output) {
                session.removeOutput(defaultOutput.output)
            }
        case .video:
            do {
                try addOutput(defaultOutput.output)
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
        await reconfigureMetalOutputs()
        return try await photoOutput.capturePhoto(with: features)
    }
    
    func recordVideo(with features: VideoFeatures) async throws -> Video {
        await reconfigureMetalOutputs()
        return try await movieOutput.recordVideo(with: features)
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
    
    private func configurePipeline() {
        previewSource.connect(to: previewTarget)
    }
    
    private func observeOutputServices() {
        photoOutput.captureActivityPublisher
            .merge(with: movieOutput.captureActivityPublisher)
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
    
    private func reconfigureMetalOutputs() async {
        if let metalOutput = photoOutput.output as? any MetalCaptureOutput,
           let imageSource = previewSource as? ImageSource {
            let currentState = await CameraState.current
            imageSource.removeAllTargets()
            configurePipeline()
            if currentState.renderMode == .metalWithFilters {
                let operation = currentState.lastFilter.makeOperation()
                operation.addTarget(metalOutput.output, atTargetIndex: 0)
                imageSource --> operation
            } else {
                imageSource --> metalOutput.output
            }
        }
    }
}
