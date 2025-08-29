//
//  FilterStack.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

@preconcurrency import AVFoundation
import Foundation
@preconcurrency import GPUImage

final class FilterStack: PreviewSource, PreviewTarget, ImageProcessingOperation, @unchecked Sendable {
    let maximumInputs: UInt = 1
    
    var sources: SourceContainer { relay.sources }
    var targets: TargetContainer { relay.targets }
    
    private let relay = ImageRelay()
    private(set) var targetsMap: [CameraFilter: (operation: ImageProcessingOperation, target: Target)]!
    private var session: AVCaptureSession?
    
    typealias Target = ImageConsumer & PreviewTarget
    
    fileprivate init(filters: [(CameraFilter, Target)]) {
        var targetsMap = [CameraFilter: (ImageProcessingOperation, Target)]()
        for (filter, target) in filters {
            let operation = filter.makeOperation()
            self --> operation --> target
            targetsMap[filter] = (operation, target)
        }
        self.targetsMap = targetsMap
    }
    
    func addTarget(_ target: some Target = MetalPreviewTarget(), for filter: CameraFilter) {
        let operation = filter.makeOperation()
        self --> operation --> target
        targetsMap[filter] = (operation, target)
    }
    
    func removeTarget(for filter: CameraFilter) {
        guard let (operation, _) = targetsMap[filter] else { return }
        operation.removeAllTargets()
        targetsMap.removeValue(forKey: filter)
    }
    
    func operation(for filter: CameraFilter) -> (any ImageProcessingOperation)? {
        targetsMap[filter]?.operation
    }
    
    func target(for filter: CameraFilter) -> Target? {
        targetsMap[filter]?.target
    }
    
    func transmitPreviousImage(to target: any ImageConsumer, atIndex index: UInt) {
        relay.transmitPreviousImage(to: target, atIndex: index)
    }
    
    func newTextureAvailable(_ texture: Texture, fromSourceIndex sourceIndex: UInt) {
        relay.newTextureAvailable(texture, fromSourceIndex: sourceIndex)
    }
    
    func connect(to target: any PreviewTarget) {
        if let session {
            target.setSession(session)
        }
    }
    
    func setSession(_ session: AVCaptureSession) {
        self.session = session
    }
}

extension FilterStack: ExpressibleByDictionaryLiteral {
    convenience init(dictionaryLiteral elements: (CameraFilter, Target)...) {
        self.init(filters: elements)
    }
}

extension FilterStack: ExpressibleByArrayLiteral {
    convenience init(arrayLiteral elements: CameraFilter...) {
        self.init(filters: elements.map { ($0, MetalPreviewTarget()) })
    }
}
