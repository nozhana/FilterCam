//
//  CustomFilter+Noop.swift
//  FilterCamWidgetsExtension
//
//  Created by Nozhan A. on 8/25/25.
//

import GPUImage

extension CustomFilter {
    func makeOperation() -> any ImageProcessingOperation {
        ImageRelay()
    }
}
