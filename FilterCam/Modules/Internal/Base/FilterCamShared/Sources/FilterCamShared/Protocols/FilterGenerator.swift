//
//  FilterGenerator.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import GPUImage

public protocol FilterGenerator {
    var title: String { get }
    var layoutIndex: Int { get }
    func makeOperation() -> any ImageProcessingOperation
}
