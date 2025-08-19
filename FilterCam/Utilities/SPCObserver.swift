//
//  SPCObserver.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import Foundation

final class SystemPreferredCameraObserver: NSObject {
    private let systemPreferredCameraKeyPath = "systemPreferredCamera"
    
    typealias CaptureDeviceStream = AsyncStream<AVCaptureDevice?>
    let changes: CaptureDeviceStream
    private let continuation: CaptureDeviceStream.Continuation
    
    override init() {
        (changes, continuation) = AsyncStream.makeStream()
        
        super.init()
        
        AVCaptureDevice.self.addObserver(self, forKeyPath: systemPreferredCameraKeyPath, options: [.new], context: nil)
    }
    
    deinit {
        continuation.finish()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case systemPreferredCameraKeyPath:
            let newDevice = change?[.newKey] as? AVCaptureDevice
            continuation.yield(newDevice)
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}
