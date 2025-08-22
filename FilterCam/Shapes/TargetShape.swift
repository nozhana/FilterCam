//
//  TargetShape.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import SwiftUI

struct TargetShape: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            let topLeading = rect.origin
            let p11 = CGPoint(x: rect.minX + rect.width / 4,
                             y: rect.minY)
            let p12 = CGPoint(x: rect.minX,
                             y: rect.minY + rect.height / 4)
            path.move(to: topLeading)
            path.addLine(to: p11)
            path.move(to: topLeading)
            path.addLine(to: p12)
            
            let topTrailing = CGPoint(x: rect.maxX, y: rect.minY)
            let p21 = CGPoint(x: rect.maxX - rect.width / 4,
                              y: rect.minY)
            let p22 = CGPoint(x: rect.maxX,
                              y: rect.minY + rect.height / 4)
            path.move(to: topTrailing)
            path.addLine(to: p21)
            path.move(to: topTrailing)
            path.addLine(to: p22)
            
            let bottomLeading = CGPoint(x: rect.minX, y: rect.maxY)
            let p31 = CGPoint(x: rect.minX + rect.width / 4,
                              y: rect.maxY)
            let p32 = CGPoint(x: rect.minX,
                              y: rect.maxY - rect.height / 4)
            path.move(to: bottomLeading)
            path.addLine(to: p31)
            path.move(to: bottomLeading)
            path.addLine(to: p32)
            
            let bottomTrailing = CGPoint(x: rect.maxX, y: rect.maxY)
            let p41 = CGPoint(x: rect.maxX - rect.width / 4,
                              y: rect.maxY)
            let p42 = CGPoint(x: rect.maxX,
                              y: rect.maxY - rect.height / 4)
            path.move(to: bottomTrailing)
            path.addLine(to: p41)
            path.move(to: bottomTrailing)
            path.addLine(to: p42)
        }
        .strokedPath(.init(lineWidth: 1, lineCap: .round, lineJoin: .round))
    }
}
