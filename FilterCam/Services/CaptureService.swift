//
//  CaptureService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Combine
import FilterCamBase
import Foundation
import GPUImage

final actor CaptureService {
    @Published private(set) var captureActivity: CaptureActivity = .idle
    @Published private(set) var isInterrupted = false
    @Published private(set) var supportsUltraWideZoom = false
    @Published private(set) var supportsCustomExposure = false
    @Published private(set) var supportsCustomWhiteBalance = false
    @Published private(set) var activeDeviceExposure = 0.5
    @Published private(set) var activeDeviceWhiteBalanceTemperature: Double = 4000
    
    nonisolated let previewSource: PreviewSource
    
    nonisolated let previewTarget: PreviewTarget
    
    nonisolated let photoOutput: any PhotoOutputService
    
    nonisolated let movieOutput: any MovieOutputService
    
    private let session: AVCaptureSession
    
    private var outputServices: [any OutputService] { [photoOutput, movieOutput] }
    
    private var activeVideoInput: AVCaptureDeviceInput? {
        didSet {
            guard let device = activeVideoInput?.device else { return }
            supportsUltraWideZoom = (device.deviceType == .builtInUltraWideCamera) || (device.isVirtualDevice && device.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera }))
            supportsCustomExposure = device.isExposureModeSupported(.locked)
            supportsCustomWhiteBalance = device.isWhiteBalanceModeSupported(.locked) && device.isLockingWhiteBalanceWithCustomDeviceGainsSupported
        }
    }
    
    private var activeAudioInput: AVCaptureDeviceInput?
    
    private(set) var captureMode = CaptureMode.photo
    
    private let deviceLookup = DeviceLookup()
    
    private let systemPreferredCamera = SystemPreferredCameraObserver()
    
    // private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    // private var rotationObservers: [AnyObject] = []
    
    private var isSetUp = false
    
    private let sessionQueue = DispatchSerialQueue(label: "com.nozhana.FilterCam.sessionQueue")
    
    private var observers = Set<NSKeyValueObservation>()
    
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        sessionQueue.asUnownedSerialExecutor()
    }
    
    init(previewSource: some PreviewSource, previewTarget: some PreviewTarget, photoOutput: any PhotoOutputService, movieOutput: any MovieOutputService, session: AVCaptureSession) {
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
        Task {
            let database: DatabaseService = ProcessInfo.isRunningPreviews ? .inMemory : .default
            let customFilters = (try? await database.list(CustomFilter.self, sortDescriptors: [.init(\.layoutIndex, order: .reverse)])) ?? []
            for filter in customFilters {
                filterStack.addTarget(for: .custom(filter))
            }
        }
        
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
        try await setupSession()
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
    
    private func setupSession() async throws {
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
            
            if #available(iOS 18.0, *), session.supportsControls {
                for control in session.controls {
                    session.removeControl(control)
                }
                let zoomControl = AVCaptureSystemZoomSlider(device: defaultCamera)
                if session.canAddControl(zoomControl) {
                    session.addControl(zoomControl)
                }
                let exposureControl = AVCaptureSystemExposureBiasSlider(device: defaultCamera)
                if session.canAddControl(exposureControl) {
                    session.addControl(exposureControl)
                }
            }
            
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
            
            zoom(to: 1, ramp: false)
            monitorSystemPreferredCamera()
            monitorExposureUpdates()
            monitorWhiteBalanceUpdates()
            updateOutputConfigurations()
            isSetUp = true
        } catch {
            throw CameraError.setupFailed
        }
    }
    
    func setCaptureMode(_ captureMode: CaptureMode) {
        session.sessionPreset = captureMode == .photo ? .photo : .high
        zoom(to: 1, ramp: false)
        self.captureMode = captureMode
        guard let defaultMovieOutput = movieOutput.output as? any DefaultCaptureOutput else { return }
        switch captureMode {
        case .photo:
            if session.outputs.contains(defaultMovieOutput.output) {
                session.removeOutput(defaultMovieOutput.output)
            }
            if let activeAudioInput {
                session.removeInput(activeAudioInput)
                self.activeAudioInput = nil
            }
        case .video:
            do {
                try addOutput(defaultMovieOutput.output)
                let defaultMic = try deviceLookup.defaultMic
                activeAudioInput = try addInput(for: defaultMic)
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
    
    func zoom(to factor: CGFloat, ramp: Bool = true) {
        guard let device = activeVideoInput?.device else { return }
        let normalizedFactor: CGFloat
        if #available(iOS 18.0, *) {
            normalizedFactor = factor / device.displayVideoZoomFactorMultiplier
        } else if device.isVirtualDevice,
               device.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera }) {
            normalizedFactor = factor / 0.5
        } else {
            normalizedFactor = factor
        }
        let clampedFactor = min(max(normalizedFactor, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if ramp {
                device.ramp(toVideoZoomFactor: clampedFactor, withRate: 4)
            } else {
                device.videoZoomFactor = clampedFactor
            }
        } catch {
            logger.error("Failed to zoom to factor \(factor): \(error)")
        }
    }
    
    func setExposure(to value: CGFloat?) {
        guard let device = activeVideoInput?.device else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if let value {
                let clampedValue = min(max(value, 0), 1)
                let normalizedBias = device.minExposureTargetBias.interpolated(towards: device.maxExposureTargetBias, amount: clampedValue)
                guard device.isExposureModeSupported(.locked) else { return }
                device.exposureMode = .locked
                device.setExposureTargetBias(normalizedBias)
            } else {
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.setExposureTargetBias(.zero)
            }
        } catch {
            logger.error("Failed to set exposure to \(String(describing: value)): \(error)")
        }
    }
    
    func setWhiteBalance(to temperature: Float?) {
        guard let device = activeVideoInput?.device else { return }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if let temperature {
                let clampedValue = min(max(temperature, 3000), 7000)
                var temperatureAndTint = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains)
                temperatureAndTint.temperature = temperature
                let targetGains = device.deviceWhiteBalanceGains(for: temperatureAndTint)
                if device.isWhiteBalanceModeSupported(.locked), device.isLockingWhiteBalanceWithCustomDeviceGainsSupported {
                    device.setWhiteBalanceModeLocked(with: targetGains)
                }
            } else {
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
            }
        } catch {
            logger.error("Failed to set white balance to \(String(describing: temperature)): \(error)")
        }
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
    
    private func monitorExposureUpdates() {
        currentDevice.observe(\.exposureTargetOffset, options: [.initial, .new]) { [weak self] device, _ in
            let offset = device.exposureTargetOffset
            let exposureValue = device.exposureTargetBias + offset
            let minBias = device.minExposureTargetBias
            let maxBias = device.maxExposureTargetBias
            let normalizedInterpolation = (exposureValue - minBias) / (maxBias - minBias)
            self?.activeDeviceExposure = Double(normalizedInterpolation)
        }
        .store(in: &observers)
    }
    
    private func monitorWhiteBalanceUpdates() {
        currentDevice.observe(\.deviceWhiteBalanceGains, options: [.initial, .new]) { [weak self] device, _ in
            let temperature = device.temperatureAndTintValues(for: device.deviceWhiteBalanceGains).temperature
            self?.activeDeviceWhiteBalanceTemperature = Double(temperature)
        }
        .store(in: &observers)
    }
    
    private func changeCaptureDevice(to device: AVCaptureDevice) {
        guard let currentInput = activeVideoInput else { fatalError("No active video input device found") }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        
        session.removeInput(currentInput)
        do {
            activeVideoInput = try addInput(for: device)
            zoom(to: 1, ramp: false)
            updateOutputConfigurations()
            monitorExposureUpdates()
            monitorWhiteBalanceUpdates()
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
