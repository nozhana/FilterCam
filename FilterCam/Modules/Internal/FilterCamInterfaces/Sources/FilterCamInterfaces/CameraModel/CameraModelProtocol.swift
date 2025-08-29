//
//  CameraModelProtocol.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/27/25.
//

import Foundation
import FilterCamShared

public protocol CameraModelProtocol: AnyObject, ObservableObject {
    var cameraState: CameraState { get }
    var captureActivity: CaptureActivity { get }
    var status: CameraStatus { get }
    var isSwitchingCameras: Bool { get }
    var shouldFlashScreen: Bool { get }
    var thumbnail: Thumbnail? { get }
    var isPaused: Bool { get }
    var focusPoint: CGPoint? { get }
    var supportsUltraWideZoom: Bool { get }
    var supportsCustomExposure: Bool { get }
    var supportsCustomWhiteBalance: Bool { get }
    var activeDeviceExposure: Double { get }
    var activeDeviceWhiteBalance: Double { get }
    
    var zoomFactor: Double { get set }
    var exposure: Double? { get set }
    var whiteBalance: Double? { get set }
    var proRAW: Bool { get set }
    var captureMode: CaptureMode { get set }
    var flashMode: FlashMode { get set }
    var qualityPrioritization: QualityPrioritization { get set }
    var aspectRatio: AspectRatio { get set }
    var renderMode: RenderMode { get set }
    var lastFilter: CameraFilter { get set }
    var showLevel: Bool { get set }
    
    var previewSource: any PreviewSource { get }
    var previewTarget: any PreviewTarget { get }
    
    @MainActor func pauseStream() async
    @MainActor func unpauseStream() async
    @MainActor func switchCamera() async
    func capturePhoto() async
    func startRecording() async
    func stopRecording() async
    func focusAndExpose(on devicePoint: CGPoint, layerPoint: CGPoint) async
}

public extension CameraModelProtocol {
    func pauseStream() async {}
    func unpauseStream() async {}
    func switchCamera() async {}
    func capturePhoto() async {}
    func startRecording() async {}
    func stopRecording() async {}
    func focusAndExpose(on devicePoint: CGPoint, layerPoint: CGPoint) async {}
}

public extension CameraModelProtocol {
    var isRunningAndActive: Bool {
        status == .running && !isPaused && !isSwitchingCameras
    }
}
