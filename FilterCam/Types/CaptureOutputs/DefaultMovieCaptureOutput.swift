//
//  DefaultMovieCaptureOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import FilterCamInterfaces
import Foundation
import AVFoundation

struct DefaultMovieCaptureOutput: DefaultCaptureOutput {
    let output: AVCaptureOutput
    
    init(output: AVCaptureMovieFileOutput = .init()) {
        self.output = output
    }
}
