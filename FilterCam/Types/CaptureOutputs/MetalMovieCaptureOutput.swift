//
//  MetalMovieCaptureOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import FilterCamInterfaces
import Foundation
import GPUImage

struct MetalMovieCaptureOutput: MetalCaptureOutput {
    let output: MovieOutput
    
    init(url: URL, size: (width: Float, height: Float) = (Size.movieDefault.width, Size.movieDefault.height)) throws {
        output = try .init(URL: url, size: .movieDefault)
    }
    
    init() {
        output = try! .init(URL: .temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .quickTimeMovie), size: .movieDefault)
    }
}

private extension Size {
    static let movieDefault = Size(width: 2880, height: 2160)
}
