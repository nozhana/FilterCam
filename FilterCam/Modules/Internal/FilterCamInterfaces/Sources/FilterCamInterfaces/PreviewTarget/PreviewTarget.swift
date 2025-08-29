//
//  PreviewTarget.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import Foundation

public protocol PreviewTarget {
    func setSession(_ session: AVCaptureSession)
}
