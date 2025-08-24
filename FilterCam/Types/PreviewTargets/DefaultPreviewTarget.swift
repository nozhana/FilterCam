//
//  DefaultPreviewTarget.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

@preconcurrency import AVFoundation
import Foundation

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
