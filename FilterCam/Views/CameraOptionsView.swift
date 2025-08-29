//
//  CameraOptionsView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/21/25.
//

import FilterCamBase
import FilterCamMacros
import FilterCamShared
import SwiftUI

@Provider(\.cameraModel, name: "model", observed: true)
struct CameraOptionsView: View {
    @State private var expandedOption: CameraOption?
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(expandedOption.map { [$0] } ?? CameraOption.allCases) { option in
                CameraOptionView(option: option, isExpanded: Binding { expandedOption == option } set: { expandedOption = $0 ? option : nil })
                    .transition(.scale.combined(with: .blurReplace))
            }
        }
    }
}

#Preview {
    CameraOptionsView()
}

@Provider(\.cameraModel, name: "model", observed: true)
private struct CameraOptionView: View {
    var option: CameraOption
    @Binding var isExpanded: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: option.systemImage(model: model))
                        .imageScale(.small)
                        .scaleEffect(isExpanded ? 1.5 : 1)
                        .frame(width: 18, height: 18)
                    if !isExpanded {
                        Text(option.title(model: model))
                            .font(.caption2.smallCaps())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .transition(.scale(0, anchor: .bottom))
                    }
                }
                .fontWeight(.light)
                .frame(width: 64, height: 44)
            }
            .foregroundStyle(option.foregroundStyle(model: model))
            if isExpanded {
                HStack(spacing: 24) {
                    switch option {
                    case .flashMode:
                        ForEach(FlashMode.allCases) { flashMode in
                            Button(flashMode.title) {
                                withAnimation(.snappy) {
                                    model.flashMode = flashMode
                                    isExpanded = false
                                }
                            }
                            .foregroundStyle(model.flashMode == flashMode ? .yellow : .primary)
                        }
                    case .qualityPrioritization:
                        ForEach(QualityPrioritization.allCases) { qualityPrioritization in
                            Button(qualityPrioritization.title) {
                                withAnimation(.snappy) {
                                    model.qualityPrioritization = qualityPrioritization
                                    isExpanded = false
                                }
                            }
                            .foregroundStyle(model.qualityPrioritization == qualityPrioritization ? .teal : .primary)
                        }
                    }
                }
                .font(.callout.smallCaps().weight(.light))
                .safeAreaPadding(.horizontal, 16)
                .transition(.move(edge: .leading).combined(with: .blurReplace))
            }
        }
        .padding(8)
        .background(.background.secondary.opacity(0.4), in: .rect(cornerRadius: 16, style: .continuous))
        .clipShape(.rect(cornerRadius: 16, style: .continuous))
    }
}

private enum CameraOption: Int, Identifiable, CaseIterable {
    case flashMode
    case qualityPrioritization
    
    var id: Int { rawValue }
    
    func title(model: CameraModel) -> String {
        switch self {
        case .flashMode:
            model.flashMode.title
        case .qualityPrioritization:
            model.qualityPrioritization.title
        }
    }
    
    func systemImage(model: CameraModel) -> String {
        switch self {
        case .flashMode:
            model.flashMode.systemImage
        case .qualityPrioritization:
            model.qualityPrioritization.systemImage
        }
    }
    
    func foregroundStyle(model: CameraModel) -> some ShapeStyle {
        let anyStyle: any ShapeStyle = switch self {
        case .flashMode:
            switch model.flashMode {
            case .on: .yellow.gradient
            case .auto: .blue.gradient
            case .off: .secondary
            }
        case .qualityPrioritization:
            switch model.qualityPrioritization {
            case .speed: .green.gradient
            case .quality: .purple.gradient
            case .balanced: .cyan.gradient
            }
        }
        return AnyShapeStyle(anyStyle)
    }
    
    func cycle(model: CameraModel) {
        switch self {
        case .flashMode:
            model.flashMode.cycle()
        case .qualityPrioritization:
            model.qualityPrioritization.cycle()
        }
    }
}

private extension CaseIterable where Self.AllCases.Element: Equatable {
    mutating func cycle() {
        let currentIndex = Self.allCases.firstIndex(of: self)!
        var nextIndex = Self.allCases.index(after: currentIndex)
        if nextIndex == Self.allCases.endIndex {
            nextIndex = Self.allCases.startIndex
        }
        self = Self.allCases[nextIndex]
    }
}
