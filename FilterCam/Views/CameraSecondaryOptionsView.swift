//
//  CameraSecondaryOptionsView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/26/25.
//

import SwiftUI

struct CameraSecondaryOptionsView: View {
    @EnvironmentObject private var model: CameraModel
    
    @State private var expandedOption: CameraOption?
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(expandedOption.map { [$0] } ?? CameraOption.allCases) { option in
                CameraOptionView(option: option, expandedOption: $expandedOption)
                    .transition(
                        .scale
                            .combined(with: .opacity)
                            .combined(with: .symbolEffect)
                    )
            }
        }
    }
}

private struct CameraOptionView: View {
    var option: CameraOption
    @Binding var expandedOption: CameraOption?
    
    @EnvironmentObject private var model: CameraModel
    
    private var isExpanded: Bool {
        get { expandedOption == option }
        nonmutating set { expandedOption = newValue ? option : nil }
    }
    
    var body: some View {
        HStack(spacing: .zero) {
            Button {
                withAnimation(.snappy(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.background.tertiary.opacity(isExpanded ? 0.5 : 0))
                        .padding(6)
                    Image(systemName: option.systemImage(model: model))
                        .contentTransition(.symbolEffect)
                        .font(.title3.bold())
                }
            }
            .foregroundStyle(Color.primary)
            .zIndex(1)
            if isExpanded {
                HStack(spacing: 16) {
                    switch option {
                    case .exposure:
                        Button(option.title(model: model)) {
                            withAnimation(.snappy) {
                                if model.exposure == nil {
                                    model.exposure = 0.5
                                } else {
                                    model.exposure = nil
                                }
                            }
                        }
                        .contentTransition(.numericText(value: model.exposure ?? 0))
                        .foregroundStyle(model.exposure == nil ? .yellow : .primary)
                        .font(.subheadline.smallCaps())
                        .bold(model.exposure == nil)
                        .frame(width: 44, alignment: .leading)
                        let binding = Binding(get: { model.exposure ?? model.activeDeviceExposure }, set: { model.exposure = $0 })
                        Ticker(value: binding, in: 0...1, step: 0.01)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(height: 16)
                    case .whiteBalance:
                        Button(option.title(model: model)) {
                            withAnimation(.snappy) {
                                if model.whiteBalance == nil {
                                    model.whiteBalance = 4000
                                } else {
                                    model.whiteBalance = nil
                                }
                            }
                        }
                        .contentTransition(.numericText(value: model.whiteBalance ?? 0))
                        .foregroundStyle(model.whiteBalance == nil ? .yellow : .primary)
                        .font(.subheadline.smallCaps())
                        .bold(model.whiteBalance == nil)
                        .frame(width: 44, alignment: .leading)
                        let binding = Binding(get: { model.whiteBalance ?? model.activeDeviceWhiteBalance }, set: { model.whiteBalance = $0 })
                        Ticker(value: binding, in: 3000...7000, step: 50)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(height: 16)
                    case .proRAW:
                        Label("Coming Soon", systemImage: "sparkles")
                    }
                }
                .disabled((!model.supportsCustomExposure && option == .exposure) || (!model.supportsCustomWhiteBalance && option == .whiteBalance))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .zIndex(0)
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .background(.background.secondary.opacity(0.5), in: .capsule)
        .clipShape(.capsule)
        .frame(height: 64)
    }
}

private enum CameraOption: Int, Identifiable, Comparable, CaseIterable {
    case exposure
    case whiteBalance
    case proRAW
    
    var id: Int { rawValue }
    
    func title(model: CameraModel) -> String {
        switch self {
        case .exposure:
            Exposure(value: model.exposure).title
        case .whiteBalance:
            WhiteBalance(value: model.whiteBalance).title
        case .proRAW:
            ProRAW(rawValue: model.proRAW).title
        }
    }
    
    func systemImage(model: CameraModel) -> String {
        switch self {
        case .exposure:
            Exposure(value: model.exposure).systemImage
        case .whiteBalance:
            WhiteBalance(value: model.whiteBalance).systemImage
        case .proRAW:
            ProRAW(rawValue: model.proRAW).systemImage
        }
    }
    
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension CameraOption {
    struct Exposure: CameraOptionable {
        var value: Double?
        
        var id: Double? { value }
        
        var title: String {
            value?.formatted(.number.precision(.fractionLength(0...2))) ?? "Auto"
        }
        
        var systemImage: String {
            if let value {
                value < 0.5 ? "sun.min.fill" : "sun.max.fill"
            } else {
                "sun.lefthalf.filled"
            }
        }
    }
    
    struct WhiteBalance: CameraOptionable {
        var value: Double?
        
        var id: Double? { value }
        
        var title: String {
            value?.formatted(.number.precision(.integerAndFractionLength(integer: 4, fraction: 0))) ?? "Auto"
        }
        
        var systemImage: String {
            if let value {
                switch value {
                case ..<4000: "thermometer.low"
                case 4000..<6000: "thermometer.medium"
                default: "thermometer.high"
                }
            } else {
                "thermometer.sun"
            }
        }
    }
    
    enum ProRAW: Int, CaseIterable, CameraOptionable {
        case off, on
        
        var id: Int { rawValue }
        
        var title: String {
            "Pro RAW"
        }
        
        var systemImage: String {
            rawValue == 1 ? "camera.metering.multispot" : "camera.metering.spot"
        }
    }
}

private extension CameraOption.ProRAW {
    init(rawValue: Bool) {
        self = rawValue ? .on : .off
    }
}
