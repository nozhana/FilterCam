//
//  Ticker.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/26/25.
//

import SwiftUI

struct Ticker<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
    @Binding var value: V
    var range: ClosedRange<V>
    var step: V.Stride = 1
    
    @State private var contentMargin: CGFloat?
    @State private var baseValue: V?
    
    @GestureState private var dragState = DragState.idle
    
    init(value: Binding<V>, in range: ClosedRange<V>, step: V.Stride = 1) {
        self._value = value
        self.range = range
        self.step = step
    }
    
    var body: some View {
        let dragGesture = DragGesture(minimumDistance: 2)
            .updating($dragState) { value, state, _ in
                state = .dragging(
                    offsetX: value.translation.width,
                    predictedEndOffsetX: value.predictedEndTranslation.width,
                    velocityX: value.velocity.width
                )
            }
            .onChanged { value in
                if baseValue == nil {
                    baseValue = self.value
                }
                let delta = -value.translation.width / 30 * CGFloat(step)
                self.value = ((baseValue ?? self.value) + V(delta)).clamped(to: range).stepped(by: V(step))
            }
            .onEnded { value in
                let delta = -value.predictedEndTranslation.width / 40 * CGFloat(step)
                let step = abs(value.velocity.width) > 150 ? V(step) * 5 : V(step)
                withAnimation(.snappy(duration: 0.25)) {
                    self.value = ((baseValue ?? self.value) + V(delta)).clamped(to: range).stepped(by: step)
                } completion: {
                    self.baseValue = nil
                }
            }
        
        GeometryReader { geometry in
            HStack(spacing: 16) {
                let stops = stride(from: range.lowerBound, through: range.upperBound, by: step).map(\.self)
                let namedStops = stride(from: range.lowerBound, through: range.upperBound, by: step * 5).map(\.self)
                ForEach(stops, id: \.self) { stop in
                    let margin = contentMargin
                    Rectangle()
                        .fill(namedStops.contains(stop) ? .yellow : .primary)
                        .frame(width: 1, height: 20)
                        .safeAreaInset(edge: .bottom, spacing: 6) {
                            if namedStops.contains(stop) {
                                Text(Double(stop), format: .number)
                                    .font(.caption2.weight(.light))
                                    .fixedSize(horizontal: true, vertical: false)
                                    .frame(width: 1)
                                    .offset(y: 8)
                            }
                        }
                        .padding(.vertical, 16)
                        .visualEffect { content, geometry in
                            let scrollViewWidth = geometry.bounds(of: .named("ticker"))!.width
                            let scrollViewCenterX = geometry.bounds(of: .named("ticker"))!.midX
                            let centerX = geometry.frame(in: .named("ticker")).midX
                            let offset = centerX - scrollViewCenterX - (margin ?? .zero)
                            let interpolation = abs(offset) / (scrollViewWidth / 2)
                            let opacity = 1.0.interpolated(towards: 0.75, amount: interpolation)
                            let blur = 0.0.interpolated(towards: 0.9, amount: interpolation)
                            let scaleY = 1.0.interpolated(towards: 0.87, amount: interpolation)
                            return content
                                .scaleEffect(y: scaleY)
                                .blur(radius: blur)
                                .opacity(opacity)
                        }
                }
            }
            .safeAreaPadding(.horizontal, contentMargin)
            .fixedSize(horizontal: true, vertical: false)
            .offset(x: -CGFloat(value.clamped(to: range) - range.lowerBound) / CGFloat(step) * 17)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .leading)
        }
        .frame(height: 64)
        .coordinateSpace(.named("ticker"))
        .onGeometryChange(for: CGFloat.self, of: \.size.width) {
            contentMargin = $0 / 2
        }
        .contentShape(.rect)
        .gesture(dragGesture)
        .sensoryFeedback(trigger: value) { oldValue, newValue in
            guard (newValue / V(step)).rounded() == newValue / V(step) else { return nil }
            if newValue == newValue.rounded() {
                return .impact(flexibility: .rigid, intensity: 0.7)
            } else {
                return newValue > oldValue ? .increase : .decrease
            }
        }
    }
}

#Preview {
    @Previewable @State var value: CGFloat = 0.5
    VStack {
        Ticker(value: $value, in: 0...1, step: 0.01)
            .frame(width: 300)
            .border(.red, width: 1)
        Text(value, format: .number.precision(.fractionLength(0...2)))
            .font(.title2)
    }
}

private extension Ticker {
    enum DragState {
        case idle
        case dragging(offsetX: CGFloat, predictedEndOffsetX: CGFloat, velocityX: CGFloat)
        
        var isDragging: Bool {
            if case .dragging = self {
                return true
            }
            return false
        }
    }
}
