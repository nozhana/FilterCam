//
//  CameraFilterConfiguration.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import SwiftUI
import GPUImage

enum CameraFilterConfiguration {
    case slider(title: LocalizedStringKey, range: ClosedRange<Double>, step: Double = 0.1, bindingFactory: (_ operation: ImageProcessingOperation) -> Binding<Float>)
    case toggle(title: LocalizedStringKey, bindingFactory: (_ operation: ImageProcessingOperation) -> Binding<Bool>)
    case button(title: LocalizedStringKey, systemImage: String? = nil, role: ButtonRole? = nil, onTapped: (_ filter: CameraFilter, _ operation: ImageProcessingOperation, _ filterStack: ImageProcessingOperation) -> Void)
}

extension CameraFilterConfiguration {
    var title: LocalizedStringKey {
        switch self {
        case .slider(let title, _, _, _): title
        case .toggle(let title, _): title
        case .button(let title, _, _, _): title
        }
    }
    
    var isSlider: Bool {
        if case .slider = self { true } else { false }
    }
    
    var isToggle: Bool {
        if case .toggle = self { true } else { false }
    }
    
    var isButton: Bool {
        if case .button  = self { true } else { false }
    }
}
