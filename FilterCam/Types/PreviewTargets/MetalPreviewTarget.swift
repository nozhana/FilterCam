//
//  MetalPreviewTarget.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import FilterCamInterfaces
import Foundation
@preconcurrency import GPUImage
import MetalKit

final class MetalPreviewTarget: @unchecked Sendable, PreviewTarget, ImageConsumer {
    let renderView: RenderView
    
    var maximumInputs: UInt { renderView.maximumInputs }
    
    var sources: GPUImage.SourceContainer { renderView.sources }
    
    var session: AVCaptureSession?
    var aspectRatio: CGFloat = 3.0/4
    
    init() {
        renderView = RenderView(frame: .zero)
    }
    
    func setSession(_ session: AVCaptureSession) {
        self.session = session
    }
    
    func newTextureAvailable(_ texture: Texture, fromSourceIndex index: UInt) {
        aspectRatio = CGFloat(texture.texture.width) / CGFloat(texture.texture.height)
        renderView.newTextureAvailable(texture, fromSourceIndex: index)
    }
}

extension PreviewTarget where Self == MetalPreviewTarget {
    static func metal() -> MetalPreviewTarget {
        .init()
    }
}
