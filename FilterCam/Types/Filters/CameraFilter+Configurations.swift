//
//  CameraFilter+Configurations.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import GPUImage
import FilterCamShared
import SwiftUI

extension CameraFilter {
    var configurations: [CameraFilterConfiguration] {
        switch self {
        case .none: []
        case .custom(let customFilter):
            [.button(title: "Delete", systemImage: "trash.fill", role: .destructive, onTapped: { filter, _, parentOperation in
                guard let filterStack = parentOperation as? FilterStack else { return }
                filterStack.removeTarget(for: filter)
                if let model = customFilter as? CustomFilter {
                    Task {
                        let database = DefaultDatabaseService.shared
                        try await database.delete(model)
                    }
                }
            })]
        case .noir: []
        case .blur:
            [.slider(title: "Radius", range: 1...100, step: 1, bindingFactory: { operation in
                Binding {
                    (operation as! GaussianBlur).blurRadiusInPixels
                } set: {
                    (operation as! GaussianBlur).blurRadiusInPixels = $0
                }
            })]
        case .sepia:
            [.slider(title: "Intensity", range: 0...1, step: 0.01, bindingFactory: { operation in
                Binding {
                    (operation as! SepiaToneFilter).intensity
                } set: {
                    (operation as! SepiaToneFilter).intensity = $0
                }
            })]
        case .haze:
            [.slider(title: "Distance", range: 0...1, bindingFactory: { operation in
                Binding {
                    (operation as! Haze).distance
                } set: {
                    (operation as! Haze).distance = $0
                }
            }),
             .slider(title: "Slope", range: 0...1, bindingFactory: { operation in
                 Binding {
                     (operation as! Haze).slope
                 } set: {
                     (operation as! Haze).slope = $0
                 }
             })]
        case .sharpen:
            [.slider(title: "Sharpness", range: 0...1, step: 0.01, bindingFactory: { operation in
                Binding {
                    (operation as! Sharpen).sharpness
                } set: {
                    (operation as! Sharpen).sharpness = $0
                }
            })]
        case .lookup:
            [.slider(title: "Intensity", range: 0...1, step: 0.01, bindingFactory: { operation in
                Binding {
                    (operation as! LookupFilter).intensity
                } set: {
                    (operation as! LookupFilter).intensity = $0
                }
            })]
        }
    }
}
