//
//  CircularZoomSlider.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import Combine
import simd
import SwiftUI

struct CircularZoomSlider: View {
    @Binding var zoomFactor: Double
    var hasPoint5X: Bool = true
    
    @State private var isExpanded = false
    @GestureState private var isDragging = false
    @State private var baseZoomFactor: Double?
    
    var body: some View {
        let expandGesture = DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
                withAnimation(.snappy) {
                    isExpanded = true
                }
            }
            .onChanged { value in
                if baseZoomFactor == nil {
                    baseZoomFactor = zoomFactor
                }
                let interpolation = -value.translation.width / 40
                zoomFactor = min(max(baseZoomFactor! + interpolation, hasPoint5X ? 0.5 : 1), 5.0)
            }
            .onEnded { _ in
                baseZoomFactor = nil
                withAnimation(.snappy) {
                    if zoomFactor < 1 {
                        zoomFactor = (zoomFactor * 10).rounded() / 10
                    } else {
                        zoomFactor = (zoomFactor * 5).rounded() / 5
                    }
                } completion: {
                    Task {
                        try? await Task.sleep(for: .seconds(1.2))
                        if !isDragging {
                            withAnimation(.snappy) {
                                isExpanded = false
                            }
                        }
                    }
                }
            }
        ZStack(alignment: .bottom) {
            ExpandedCircularZoomSlider(zoomFactor: zoomFactor, hasPoint5X: hasPoint5X)
                .scaleEffect(isExpanded ? 1 : 0, anchor: .bottom)
                .opacity(isExpanded ? 1 : 0)
                .zIndex(0)
            HStack(spacing: 8) {
                let isPointFive = zoomFactor < 1.0
                if hasPoint5X {
                    Group {
                        if isPointFive {
                            Text(zoomFactor, format: .number.precision(.fractionLength(0...1))) + Text(verbatim: "x")
                        } else {
                            Text("0.5")
                        }
                    }
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .foregroundStyle(isPointFive ? Color.accent : .primary)
                    .padding(8)
                    .background(.background.secondary.opacity(0.5), in: .circle)
                    .scaleEffect(isPointFive ? 1 : 0.75)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            zoomFactor = 0.5
                        }
                    }
                }
                Group {
                    if isPointFive {
                        Text("1")
                    } else {
                        Text(zoomFactor, format: .number.precision(.fractionLength(0...1))) + Text(verbatim: "x")
                    }
                }
                .font(.caption2.bold())
                .lineLimit(1)
                .foregroundStyle(isPointFive ? Color.primary : .accent)
                .padding(8)
                .background(.background.secondary.opacity(0.5), in: .circle)
                .scaleEffect(isPointFive ? 0.9 : 1)
                .onTapGesture {
                    withAnimation(.snappy) {
                        zoomFactor = 1
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.background.tertiary.opacity(0.4), in: .capsule)
            .scaleEffect(isExpanded ? 0 : 1)
            .opacity(isExpanded ? 0 : 1)
            .offset(y: -6)
            .zIndex(1)
        }
        .gesture(expandGesture)
        .sensoryFeedback(trigger: zoomFactor) { oldValue, newValue in
            if newValue.truncatingRemainder(dividingBy: 1) < 0.1,
               oldValue.truncatingRemainder(dividingBy: 1) >= 0.1 {
                return .impact(flexibility: .rigid, intensity: 0.8)
            }
            if (newValue * 10).truncatingRemainder(dividingBy: 2) < 0.5,
               (oldValue * 10).truncatingRemainder(dividingBy: 2) >= 0.5 {
                return newValue > oldValue ? .increase : .decrease
            }
            return nil
        }
    }
}

#Preview {
    @Previewable @State var zoom = 1.0
    CircularZoomSlider(zoomFactor: $zoom)
}

private struct ExpandedCircularZoomSlider: View {
    var zoomFactor: Double
    var hasPoint5X: Bool = true
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
            RadialLayoutView(data: Array(0..<60)) { index in
                let isFifth = index % 5 == 0
                let zoom: Double = switch index {
                case (40..<45):
                    0.5 + Double(index - 40) * 0.1
                case (45..<60):
                    1 + Double(index - 45) * 0.2
                case (0...5):
                    4 + Double(index) * 0.2
                default:
                    0
                }
                Rectangle()
                    .fill(isFifth ? .secondary : .tertiary)
                    .frame(width: 1, height: isFifth ? 20 : 8)
                    .frame(height: 20, alignment: .bottom)
                    .mask {
                        let delta = abs(zoomFactor - zoom)
                        let interpolation = simd_smoothstep(0, zoom < 1 ? 0.1 : 0.2, delta)
                        Rectangle()
                            .scaleEffect(interpolation, anchor: .top)
                    }
                    .overlay(alignment: .top) {
                        if isFifth {
                            let isInRange = ((zoomFactor - 0.1)...(zoomFactor + 0.1)) ~= zoom
                            (Text(zoom, format: .number.precision(.fractionLength(0...1))) + Text(verbatim: "x"))
                                .font(.caption.lowercaseSmallCaps().weight(isInRange ? .medium : .light))
                                .foregroundStyle(isInRange ? .yellow : .primary)
                                .scaleEffect(isInRange ? 1.25 : 1, anchor: .top)
                                .animation(.smooth, value: zoomFactor)
                                .fixedSize()
                                .rotationEffect(.degrees(180))
                                .offset(y: -24)
                        }
                    }
                    .opacity(hasPoint5X ? 1 : (0.5..<1) ~= zoom ? 0.5 : 1)
                    .opacity((0.5...5) ~= zoom ? 1 : 0)
            }
            .rotationEffect(.degrees((zoomFactor - 1) * -30 * (zoomFactor < 1 ? 2 : 1)))
            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .frame(width: 8, height: 12)
                .foregroundStyle(.yellow)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 300, height: 300)
        .fixedSize(horizontal: false, vertical: true)
        .frame(height: 150, alignment: .top)
        .clipped()
    }
}

#Preview {
    ExpandedCircularZoomSlider(zoomFactor: 1.0)
}
