//
//  CaptureOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import AVFoundation
import Foundation
import GPUImage

protocol CaptureOutput {
    associatedtype OutputType
    var output: OutputType { get }
}

protocol DefaultCaptureOutput: CaptureOutput where OutputType: AVCaptureOutput {}

protocol MetalCaptureOutput: CaptureOutput where OutputType: ImageConsumer {}
