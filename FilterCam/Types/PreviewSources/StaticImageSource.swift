//
//  StaticImageSource.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

@preconcurrency import AVFoundation
@preconcurrency import GPUImage
import UIKit

final class StaticImageSource: PreviewSource, ImageSource, @unchecked Sendable {
    let image: UIImage
    private let input: PictureInput
    
    private var session: AVCaptureSession?
    
    var targets: TargetContainer { input.targets }
    
    init(image: UIImage, session: AVCaptureSession? = nil) {
        self.image = image
        self.input = .init(image: image)
        self.session = session
    }
    
    func connect(to target: any PreviewTarget) {
        if let session {
            target.setSession(session)
        }
        if let consumer = target as? ImageConsumer {
            input.removeAllTargets()
            input --> consumer
            input.processImage()
        }
    }
    
    func transmitPreviousImage(to target: any ImageConsumer, atIndex index: UInt) {
        input.transmitPreviousImage(to: target, atIndex: index)
    }
}

extension PreviewSource where Self == StaticImageSource {
    static func staticImage(_ image: UIImage, session: AVCaptureSession? = nil) -> StaticImageSource {
        .init(image: image, session: session)
    }
}
