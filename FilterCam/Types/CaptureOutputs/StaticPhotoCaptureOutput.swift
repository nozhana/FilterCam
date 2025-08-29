//
//  StaticPhotoCaptureOutput.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/27/25.
//

import FilterCamInterfaces
import UIKit

struct StaticPhotoCaptureOutput: CaptureOutput {
    let output: UIImage
}

extension CaptureOutput where Self == StaticPhotoCaptureOutput {
    static var staticPhoto: StaticPhotoCaptureOutput { .init(output: .camPreview) }
    
    static func staticPhoto(_ image: UIImage) -> StaticPhotoCaptureOutput { .init(output: image) }
}
