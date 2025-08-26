//
//  ScrollRevealingModifier.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/26/25.
//

import SwiftUI

struct ScrollRevealingModifier: ViewModifier {
    var axis: Axis.Set = .horizontal
    
    func body(content: Content) -> some View {
        content
            .visualEffect { effect, proxy in
                guard let scrollBounds = proxy.bounds(of: .scrollView) else {
                    return effect.offset()
                }
                let frame = proxy.frame(in: .scrollView)
                let offset: CGFloat
                if axis == .horizontal {
                    offset = frame.minX - scrollBounds.minX
                } else {
                    offset = frame.minY - scrollBounds.minY
                }
                let targetOffset = -offset * 0.5
                if axis == .horizontal {
                    return effect
                        .offset(x: targetOffset)
                } else {
                    return effect
                        .offset(y: targetOffset)
                }
            }
            .mask {
                Rectangle()
                    .visualEffect { effect, proxy in
                        guard let scrollBounds = proxy.bounds(of: .scrollView) else {
                            return effect
                                .scaleEffect()
                        }
                        let frame = proxy.frame(in: .scrollView)
                        let offset: CGFloat
                        let offsetFraction: CGFloat
                        if axis == .horizontal {
                            offset = frame.minX - scrollBounds.minX
                            offsetFraction = (offset * 0.5 / scrollBounds.width)
                        } else {
                            offset = frame.minY - scrollBounds.minY
                            offsetFraction = (offset * 0.5 / scrollBounds.height)
                        }
                        let remainingFraction = 1 - offsetFraction
                        let anchor: UnitPoint
                        if axis == .horizontal {
                            anchor = offset < 0 ? .trailing : .leading
                            return effect
                                .scaleEffect(x: remainingFraction, anchor: anchor)
                        } else {
                            anchor = offset < 0 ? .bottom : .top
                            return effect
                                .scaleEffect(y: remainingFraction, anchor: anchor)
                        }
                    }
            }
    }
}

extension View {
    func scrollRevealing(axis: Axis.Set = .horizontal) -> some View {
        modifier(ScrollRevealingModifier(axis: axis))
    }
}

#Preview("Horizontal") {
    let images: [ImageResource] = [.camPreview, .donut]
    
    ScrollView(.horizontal) {
        HStack(spacing: .zero) {
            ForEach(images, id: \.self) { resource in
                Image(resource)
                    .resizable()
                    .scaledToFill()
                    .containerRelativeFrame(.horizontal)
                    .clipped()
            }
            .scrollRevealing()
        }
        .scrollTargetLayout()
    }
    .scrollTargetBehavior(.viewAligned(limitBehavior: .backport.alwaysByOne))
    // .contentMargins(20, for: .scrollContent)
}

#Preview("Vertical") {
    let images: [ImageResource] = [.camPreview, .donut]
    
    ScrollView {
        VStack(spacing: .zero) {
            ForEach(images, id: \.self) { resource in
                Image(resource)
                    .resizable()
                    .scaledToFill()
                    .containerRelativeFrame(.vertical)
                    .clipped()
            }
            .scrollRevealing(axis: .vertical)
        }
        .scrollTargetLayout()
    }
    .scrollTargetBehavior(.viewAligned(limitBehavior: .backport.alwaysByOne))
}
