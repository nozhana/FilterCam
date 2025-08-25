//
//  FilterGenerator.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import GPUImage

protocol FilterGenerator {
    func makeOperation() -> any ImageProcessingOperation
}
