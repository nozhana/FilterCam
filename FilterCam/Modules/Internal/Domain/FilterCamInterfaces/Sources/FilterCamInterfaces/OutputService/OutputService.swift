//
//  OutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Combine
import FilterCamShared
import Foundation

public protocol OutputService {
    associatedtype Output: CaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var captureActivityPublisher: AnyPublisher<CaptureActivity, Never> { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

public extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        if let avOutput = output.output as? AVCaptureOutput {
            avOutput.connection(with: .video)?.videoRotationAngle = angle
        }
    }
    
    func updateConfiguration(for device: AVCaptureDevice) {}
}
