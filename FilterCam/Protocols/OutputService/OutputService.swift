//
//  OutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Combine
import Foundation

protocol OutputService {
    associatedtype Output: CaptureOutput
    var output: Output { get }
    var captureActivity: CaptureActivity { get }
    var captureActivityPublisher: AnyPublisher<CaptureActivity, Never> { get }
    func updateConfiguration(for device: AVCaptureDevice)
    func setVideoRotationAngle(_ angle: CGFloat)
}

extension OutputService {
    func setVideoRotationAngle(_ angle: CGFloat) {
        if let defaultOutput = output as? any DefaultCaptureOutput {
            defaultOutput.output.connection(with: .video)?.videoRotationAngle = angle
        }
    }
    
    func updateConfiguration(for device: AVCaptureDevice) {}
}
