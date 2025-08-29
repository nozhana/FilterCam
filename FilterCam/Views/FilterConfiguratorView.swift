//
//  FilterConfiguratorView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import FilterCamCore
import FilterCamShared
import FilterCamMacros
import GPUImage
import SwiftUI

@Provider(\.cameraModel, name: "model", observed: true)
struct FilterConfiguratorView: View {
    var filter: CameraFilter
    var operation: ImageProcessingOperation
    
    var body: some View {
        if filter.configurations.isEmpty {
            Label("No configurations available", systemImage: "questionmark.circle.dashed")
                .foregroundStyle(.secondary)
        } else {
            ForEach(filter.configurations.enumerated().map(\.self), id: \.offset) { (offset, configuration) in
                switch configuration {
                case .slider(let title, let range, let step, let bindingFactory):
                    let floatBinding = bindingFactory(operation)
                    let doubleBinding = Binding { Double(floatBinding.wrappedValue) } set: { floatBinding.wrappedValue = Float($0) }
                    HStack(spacing: 16) {
                        Text(title)
                            .foregroundStyle(.secondary)
                        Slider(value: doubleBinding, in: range, step: step)
                    }
                case .toggle(let title, let bindingFactory):
                    let boolBinding = bindingFactory(operation)
                    Toggle(title, isOn: boolBinding)
                case .button(let title, let systemImage, let role, let onTapped):
                    let action = {
                        guard let filterStack = model.previewTarget as? ImageProcessingOperation else { return }
                        onTapped(filter, operation, filterStack)
                    }
                    if let systemImage {
                        Button(title, systemImage: systemImage, role: role, action: action)
                    } else {
                        Button(title, role: role, action: action)
                    }
                }
            }
        }
    }
}

#Preview {
    FilterConfiguratorView(filter: .sepia(), operation: CameraFilter.sepia().makeOperation())
}
