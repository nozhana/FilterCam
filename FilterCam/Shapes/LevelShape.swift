//
//  LevelShape.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import SwiftUI

struct LevelShape: Shape, Animatable {
    var angle: Angle = .zero
    
    var animatableData: Double {
        get { angle.radians }
        set { angle = .radians(newValue) }
    }
    
    nonisolated func path(in rect: CGRect) -> Path {
        let leading = CGPoint(x: rect.minX, y: rect.midY)
        let trailing = CGPoint(x: rect.maxX, y: rect.midY)
        
        let p1 = leading.applying(.init(translationX: rect.width / 10, y: 0))
        let p2 = trailing.applying(.init(translationX: -rect.width / 10, y: 0))
        
        let p3 = p1.applying(.init(translationX: rect.width / 40, y: 0))
        let p4 = p2.applying(.init(translationX: -rect.width / 40, y: 0))
        
        return Path { path in
            path.move(to: leading)
            path.addLine(to: p1)
            path.move(to: p2)
            path.addLine(to: trailing)
            var subPath = Path()
            subPath.move(to: p3)
            subPath.addLine(to: p4)
            path.addPath(subPath.rotation(-angle, anchor: .center).path(in: rect))
        }
    }
}

#Preview {
    PhaseAnimator([0.0, .pi / 6, -Double.pi / 6, .pi / 3, -Double.pi / 3]) { phase in
        LevelShape(angle: .radians(phase))
            .stroke(lineWidth: 2)
    }
    .frame(width: 150, height: 150)
}
