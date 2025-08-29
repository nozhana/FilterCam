//
//  DefaultPreviewSource.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

@preconcurrency import AVFoundation
import FilterCamInterfaces
import Foundation

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
