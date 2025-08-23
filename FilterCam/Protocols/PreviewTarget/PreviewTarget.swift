//
//  PreviewTarget.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import Foundation

protocol PreviewTarget {
    func setSession(_ session: AVCaptureSession)
}

final class DefaultPreviewTarget: PreviewTarget {
    var session: AVCaptureSession?
    
    func setSession(_ session: AVCaptureSession) {
        self.session = session
    }
}

extension PreviewTarget where Self == DefaultPreviewTarget {
    static func `default`() -> DefaultPreviewTarget {
        .init()
    }
}
