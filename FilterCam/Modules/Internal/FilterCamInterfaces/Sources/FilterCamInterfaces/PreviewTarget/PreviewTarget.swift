//
//  PreviewTarget.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import Foundation
@preconcurrency import GPUImage

public protocol PreviewTarget {
    func setSession(_ session: AVCaptureSession)
}
