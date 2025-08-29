//
//  FilterChain.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import FilterCamShared
import Foundation
@preconcurrency import GPUImage

final class FilterChain: PreviewSource, PreviewTarget, ImageProcessingOperation, @unchecked Sendable {
    private(set) var filters: [CameraFilter: ImageProcessingOperation]
    private let operationGroup: OperationGroup
    
    let maximumInputs: UInt = 1
    
    var sources: GPUImage.SourceContainer { operationGroup.sources }
    var targets: GPUImage.TargetContainer { operationGroup.targets }
    
    var session: AVCaptureSession?
    
    init(filters: [CameraFilter: ImageProcessingOperation]) {
        self.filters = filters
        self.operationGroup = OperationGroup()
        operationGroup.configureGroup { input, output in
            var current: any ImageProcessingOperation = input
            for filter in filters.sorted(using: KeyPathComparator(\.key)).map(\.value) {
                current --> filter
                current = filter
            }
            current --> output
        }
    }
    
    func reset(with filters: [CameraFilter: ImageProcessingOperation]) {
        self.filters.values.forEach { $0.removeAllTargets() }
        self.filters.removeAll()
        self.filters = filters
        operationGroup.configureGroup { input, output in
            input.removeAllTargets()
            var current: any ImageProcessingOperation = input
            for filter in filters.sorted(using: KeyPathComparator(\.key)).map(\.value) {
                current --> filter
                current = filter
            }
            current --> output
        }
    }
    
    func reset(with filters: [CameraFilter]) {
        reset(with: Dictionary(uniqueKeysWithValues: filters.map { ($0, $0.makeOperation()) }))
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
        self.init(filters: Dictionary(uniqueKeysWithValues: filters.map { ($0, $0.makeOperation()) }))
    }
}

extension FilterChain: ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: CameraFilter...) {
        self.init(filters: elements)
    }
}

extension FilterChain: ExpressibleByDictionaryLiteral {
    convenience init(dictionaryLiteral elements: (CameraFilter, ImageProcessingOperation)...) {
        self.init(filters: Dictionary(uniqueKeysWithValues: elements))
    }
}
