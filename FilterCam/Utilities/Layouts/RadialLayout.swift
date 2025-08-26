//
//  RadialLayout.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import SwiftUI

struct RadialLayout: Layout {
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        var radius = min(bounds.size.width, bounds.size.height) / 2
        if let maxHeight = subviews.map({ $0.sizeThatFits(proposal).height }).max() {
            radius -= maxHeight / 2
        }
        
        let angle = Angle.degrees(360.0 / Double(subviews.count)).radians
        
        let ranks = subviews.map { subview in
            subview[Rank.self]
        }
        let offset = getOffset(ranks)
        
        for (index, subview) in subviews.enumerated() {
            var point = CGPoint(x: radius, y: 0)
                .applying(CGAffineTransform(
                    rotationAngle: angle * Double(index) + offset))
            
            point.x += bounds.midX
            point.y += bounds.midY
            
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}

extension RadialLayout {
    private func getOffset(_ ranks: [Int]) -> Double {
        guard ranks.count == 3,
              !ranks.allSatisfy({ $0 == ranks.first }) else { return 0.0 }
        
        var fraction: Double
        if ranks[0] == 1 {
            fraction = residual(rank1: ranks[1], rank2: ranks[2])
        } else if ranks[1] == 1 {
            fraction = -1 + residual(rank1: ranks[2], rank2: ranks[0])
        } else {
            fraction = 1 + residual(rank1: ranks[0], rank2: ranks[1])
        }
        
        return fraction * 2.0 * Double.pi / 3.0
    }
    
    private func residual(rank1: Int, rank2: Int) -> Double {
        if rank1 == 1 {
            return -0.5
        } else if rank2 == 1 {
            return 0.5
        } else if rank1 < rank2 {
            return -0.25
        } else if rank1 > rank2 {
            return 0.25
        } else {
            return 0
        }
    }
}

private struct Rank: LayoutValueKey {
    static let defaultValue: Int = 1
}

extension View {
    func rank(_ value: Int) -> some View {
        layoutValue(key: Rank.self, value: value)
    }
}

struct RadialLayoutView<Data, Content>: View where Data: RandomAccessCollection, Content: View {
    var data: Data
    @ViewBuilder var content: (Data.Element) -> Content
    
    var body: some View {
        RadialLayout {
            let sector = Angle.degrees(360 / Double(data.count))
            ForEach(data.enumerated().map(\.self), id: \.offset) { (offset, element) in
                let angle = sector * Double(offset) - .degrees(90)
                content(element)
                    .rotationEffect(angle)
            }
        }
    }
}
