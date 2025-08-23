//
//  PreviewSource.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

@preconcurrency import AVFoundation
import Foundation

protocol PreviewSource: Sendable {
    func connect(to target: PreviewTarget)
}

struct DefaultPreviewSource: PreviewSource {
    private let session: AVCaptureSession
    
    init(session: AVCaptureSession) {
        self.session = session
    }
    
    func connect(to target: any PreviewTarget) {
        target.setSession(session)
    }
}

extension PreviewSource where Self == DefaultPreviewSource {
    static func `default`(session: AVCaptureSession) -> DefaultPreviewSource {
        .init(session: session)
    }
}
