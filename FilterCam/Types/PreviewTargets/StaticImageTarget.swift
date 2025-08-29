//
//  StaticImageTarget.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

@preconcurrency import AVFoundation
import FilterCamInterfaces
import UIKit

struct StaticImageTarget: PreviewTarget {
    let image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    func setSession(_ session: AVCaptureSession) {}
}

extension StaticImageTarget {
    init(source: StaticImageSource) {
        self.image = source.image
    }
}

extension PreviewTarget where Self == StaticImageTarget {
    static func staticImage(_ image: UIImage) -> StaticImageTarget {
        .init(image: image)
    }
}
