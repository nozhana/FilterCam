//
//  FilterConfiguratorView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import SwiftUI

struct FilterConfiguratorView: View {
    var filter: CameraFilter
    var filterStack: FilterStack
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if filter.configurations.isEmpty {
                Text("No configurations available")
                    .font(.caption.bold().smallCaps())
            } else {
                ForEach(filter.configurations.enumerated().map(\.self), id: \.offset) { (offset, configuration) in
                    switch configuration {
                    case .slider(let title, let range, let step, let bindingFactory):
                        if let operation = filterStack.operation(for: filter) {
                            let floatBinding = bindingFactory(operation)
                            let doubleBinding = Binding { Double(floatBinding.wrappedValue) } set: { floatBinding.wrappedValue = Float($0) }
                            HStack(spacing: 16) {
                                Text(title)
                                    .foregroundStyle(.secondary)
                                Slider(value: doubleBinding, in: range, step: step)
                            }
                            .font(.caption.smallCaps().weight(.heavy))
                        }
                    case .toggle(let title, let bindingFactory):
                        if let operation = filterStack.operation(for: filter) {
                            let boolBinding = bindingFactory(operation)
                            Toggle(title, isOn: boolBinding)
                                .font(.caption.smallCaps().weight(.heavy))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background.secondary.opacity(0.5), in: .rect(cornerRadius: 12))
    }
}

#Preview {
    FilterConfiguratorView(filter: .sepia(), filterStack: [.sepia()])
}
