//
//  CameraFilter.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

import Foundation
import GPUImage

enum CameraFilter {
    case noir
    case sepia(intensity: Float = 0.9)
    case haze(distance: Float = 0.2, slope: Float = 0.0)
    case sharpen(sharpness: Float = 0.5)
    
    func makeOperation() -> any ImageProcessingOperation {
        switch self {
        case .noir: return Luminance()
        case .sepia(let intensity):
            let sepia = SepiaToneFilter()
            sepia.intensity = intensity
            return sepia
        case .haze(let distance, let slope):
            let haze = Haze()
            haze.distance = distance
            haze.slope = slope
            return haze
        case .sharpen(let sharpness):
            let sharpen = Sharpen()
            sharpen.sharpness = sharpness
            return sharpen
        }
    }
}
