//
//  FilterChain.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import Foundation
@preconcurrency import GPUImage

final class FilterChain: PreviewSource, PreviewTarget, ImageProcessingOperation, @unchecked Sendable {
    private let filters: [ImageProcessingOperation]
    private let operationGroup: OperationGroup
    
    let maximumInputs: UInt = 1
    
    var sources: GPUImage.SourceContainer { operationGroup.sources }
    var targets: GPUImage.TargetContainer { operationGroup.targets }
    
    var session: AVCaptureSession?
    
    init(filters: [ImageProcessingOperation]) {
        self.filters = filters
        self.operationGroup = OperationGroup()
        operationGroup.configureGroup { input, output in
            var currentOperation: any ImageProcessingOperation = input
            for filter in filters {
                currentOperation --> filter
                currentOperation = filter
            }
            currentOperation --> output
        }
    }
    
    func connect(to target: any PreviewTarget) {
        if let session {
            target.setSession(session)
        }
        if let nextConsumer = target as? ImageConsumer {
            operationGroup.removeAllTargets()
            operationGroup --> nextConsumer
        }
    }
    
    func setSession(_ session: AVCaptureSession) {
        self.session = session
    }
    
    func newTextureAvailable(_ texture: GPUImage.Texture, fromSourceIndex sourceIndex: UInt) {
        operationGroup.newTextureAvailable(texture, fromSourceIndex: sourceIndex)
    }
    
    func transmitPreviousImage(to target: any GPUImage.ImageConsumer, atIndex index: UInt) {
        operationGroup.transmitPreviousImage(to: target, atIndex: index)
    }
}

extension FilterChain {
    convenience init(filters: [CameraFilter]) {
        self.init(filters: filters.map { $0.makeOperation() })
    }
}
