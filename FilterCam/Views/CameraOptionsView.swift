//
//  CameraOptionsView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/21/25.
//

import simd
import SwiftUI

struct CameraOptionsView: View {
    @EnvironmentObject private var model: CameraModel
    
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
        .environmentObject(CameraModel())
}

private struct CameraOptionView: View {
    var option: CameraOption
    @Binding var isExpanded: Bool
    
    @EnvironmentObject private var model: CameraModel
    
    @State private var dragXOffset = CGFloat.zero
    
    var body: some View {
        HStack(spacing: 16) {
            let dragGesture = DragGesture(minimumDistance: isExpanded ? 9999 : 10)
                .onChanged { value in
                    let negativeOffset = min(0, value.translation.width)
                    let interpolation = simd_smoothstep(0, -100, negativeOffset)
                    dragXOffset = 0.interpolated(towards: -96, amount: interpolation)
                }
                .onEnded { value in
                    if value.predictedEndTranslation.width < -100 {
                        withAnimation(.linear(duration: 0.01)) {
                            option.cycle(model: model)
                            dragXOffset = .zero
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragXOffset = .zero
                        }
                    }
                }
            
            Button {
                withAnimation(.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 32) {
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
                    .foregroundStyle(option.foregroundStyle(model: model))
                    .frame(width: 64, height: 44)
                    VStack(spacing: 6) {
                        Image(systemName: option.nextSystemImage(model: model))
                            .imageScale(.small)
                            .frame(width: 18, height: 18)
                        Text(option.nextTitle(model: model))
                            .font(.caption2.smallCaps())
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .transition(.scale(0, anchor: .bottom))
                    }
                    .foregroundStyle(Color.secondary)
                    .frame(width: 64, height: 44)
                }
                .fontWeight(.light)
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: dragXOffset)
                .frame(width: 64, height: 44, alignment: .leading)
                .clipped()
                .gesture(dragGesture)
            }
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
                    case .aspectRatio:
                        ForEach(AspectRatio.allCases) { aspectRatio in
                            Button(aspectRatio.title) {
                                withAnimation(.snappy) {
                                    model.aspectRatio = aspectRatio
                                    isExpanded = false
                                }
                            }
                            .foregroundStyle(model.aspectRatio == aspectRatio ? .orange : .primary)
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
    case aspectRatio
    
    var id: Int { rawValue }
    
    func title(model: CameraModel) -> String {
        switch self {
        case .flashMode:
            model.flashMode.title
        case .qualityPrioritization:
            model.qualityPrioritization.title
        case .aspectRatio:
            model.aspectRatio.title
        }
    }
    
    func nextTitle(model: CameraModel) -> String {
        switch self {
        case .flashMode:
            model.flashMode.nextElement.title
        case .qualityPrioritization:
            model.qualityPrioritization.nextElement.title
        case .aspectRatio:
            model.aspectRatio.nextElement.title
        }
    }
    
    func systemImage(model: CameraModel) -> String {
        switch self {
        case .flashMode:
            model.flashMode.systemImage
        case .qualityPrioritization:
            model.qualityPrioritization.systemImage
        case .aspectRatio:
            model.aspectRatio.systemImage
        }
    }
    
    func nextSystemImage(model: CameraModel) -> String {
        switch self {
        case .flashMode:
            model.flashMode.nextElement.systemImage
        case .qualityPrioritization:
            model.qualityPrioritization.nextElement.systemImage
        case .aspectRatio:
            model.aspectRatio.nextElement.systemImage
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
        case .aspectRatio: .primary
        }
        return AnyShapeStyle(anyStyle)
    }
    
    func cycle(model: CameraModel) {
        switch self {
        case .flashMode:
            model.flashMode.cycle()
        case .qualityPrioritization:
            model.qualityPrioritization.cycle()
        case .aspectRatio:
            model.aspectRatio.cycle()
        }
    }
}

private extension CaseIterable where Self.AllCases.Element: Equatable {
    var nextElement: Self {
        let currentIndex = Self.allCases.firstIndex(of: self)!
        var nextIndex = Self.allCases.index(after: currentIndex)
        if nextIndex == Self.allCases.endIndex {
            nextIndex = Self.allCases.startIndex
        }
        return Self.allCases[nextIndex]
    }
    
    mutating func cycle() {
        self = nextElement
    }
}
