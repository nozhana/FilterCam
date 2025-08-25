//
//  LevelView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import simd
import SwiftUI

struct LevelView: View {
    @StateObject private var model = Model()
    
    var body: some View {
        LevelShape(angle: model.angle)
            .stroke(model.almostLevel ? .yellow : .primary, lineWidth: model.perfectlyLevel ? 2 : 1)
            .opacity(model.opacity)
            .animation(.snappy, value: model.almostLevel != model.perfectlyLevel)
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 1), trigger: model.perfectlyLevel) { $1 }
            .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.7), trigger: model.almostLevel) { $1 }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: model.showLevel) { $1 }
    }
}

#Preview {
    LevelView()
        .frame(width: 150, height: 150)
}

extension LevelView {
    final class Model: ObservableObject {
        static let showLevelThreshold: Angle = .degrees(45)
        static let almostLevelThreshold: Angle = .degrees(20)
        static let perfectlyLevelThreshold: Angle = .degrees(2.5)
        
        @Published private(set) var angle = Angle.zero
        
        private let motionService = MotionService.shared
        
        init() {
            observeState()
            Task { await motionService.startUpdates() }
        }
        
        deinit {
            Task { await MotionService.shared.stopUpdates() }
        }
        
        private func observeState() {
            Task {
                for await attitude in await motionService.attitudes {
                    await MainActor.run {
                        angle = .radians(attitude.roll)
                    }
                }
            }
        }
        
        var showLevel: Bool {
            (-Self.showLevelThreshold...Self.showLevelThreshold) ~= angle
        }
        
        var opacity: Double {
            simd_smoothstep(Self.showLevelThreshold.degrees, 0, abs(angle.degrees))
        }
        
        var almostLevel: Bool {
            (-Self.almostLevelThreshold...Self.almostLevelThreshold) ~= angle
        }
        
        var perfectlyLevel: Bool {
            (-Self.perfectlyLevelThreshold...Self.perfectlyLevelThreshold) ~= angle
        }
    }
}
