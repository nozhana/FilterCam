//
//  VideoFeatures.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import Foundation

public struct VideoFeatures {
    public var flashMode: FlashMode = .firstAvailable
    
    public init(flashMode: FlashMode = .firstAvailable) {
        self.flashMode = flashMode
    }
    
    public static let `default` = VideoFeatures()
}
