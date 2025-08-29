//
//  CaptureOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import AVFoundation
import Foundation
import GPUImage

public protocol CaptureOutput {
    associatedtype OutputType
    var output: OutputType { get }
}

public protocol DefaultCaptureOutput: CaptureOutput where OutputType: AVCaptureOutput {}

public protocol MetalCaptureOutput: CaptureOutput where OutputType: ImageConsumer {}
