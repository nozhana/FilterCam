//
//  CameraFilterConfiguration.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import SwiftUI
import GPUImage

enum CameraFilterConfiguration {
    case slider(title: LocalizedStringKey, range: ClosedRange<Double>, step: Double = 0.1, bindingFactory: (ImageProcessingOperation) -> Binding<Float>)
    case toggle(title: LocalizedStringKey, bindingFactory: (ImageProcessingOperation) -> Binding<Bool>)
}
