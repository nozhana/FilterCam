//
//  MetalCameraSource.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import Foundation
import FilterCamShared
@preconcurrency import GPUImage

struct MetalCameraSource: PreviewSource, ImageSource {
    let camera: Camera
    
    var targets: TargetContainer { camera.targets }
    
    var session: AVCaptureSession { camera.captureSession }
    
    init(sessionPreset: AVCaptureSession.Preset = .photo, device: AVCaptureDevice? = nil, cameraPosition: CameraPosition = .unspecified) throws {
        self.camera = try Camera(sessionPreset: sessionPreset, cameraDevice: device, location: .init(cameraPosition: cameraPosition))
    }
    
    func connect(to target: any PreviewTarget) {
        target.setSession(camera.captureSession)
        if let consumer = target as? ImageConsumer {
            camera.removeAllTargets()
            camera --> consumer
        }
    }
    
    func transmitPreviousImage(to target: any ImageConsumer, atIndex index: UInt) {
        camera.transmitPreviousImage(to: target, atIndex: index)
    }
    
    func start() {
        camera.startCapture()
    }
    
    func stop() {
        camera.stopCapture()
    }
}

private extension PhysicalCameraLocation {
    init(cameraPosition: CameraPosition) {
        self = switch cameraPosition {
        case .unspecified, .back: .backFacing
        case .front: .frontFacing
        }
    }
}
