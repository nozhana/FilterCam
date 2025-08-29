//
//  DefaultPhotoCaptureOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import Foundation
import AVFoundation

struct DefaultPhotoCaptureOutput: DefaultCaptureOutput {
    let output: AVCapturePhotoOutput
    
    init(output: AVCapturePhotoOutput = .init()) {
        self.output = output
    }
}
