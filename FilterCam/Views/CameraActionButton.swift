//
//  CameraActionButton.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import simd
import FilterCamBase
import FilterCamMacros
import SwiftUI

@DependencyProvider(.cameraModel)
struct CameraActionButton: View {
    @State private var dragXOffset = CGFloat.zero
    
    var body: some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                switch model.captureMode {
                case .photo:
                    let xOffset = min(0, max(-160, value.translation.width))
                    let interpolation = simd_smoothstep(0, -160, xOffset)
                    dragXOffset = 0.interpolated(towards: -70, amount: interpolation)
                case .video:
                    let xOffset = min(160, max(0, value.translation.width))
                    let interpolation = simd_smoothstep(0, 160, xOffset)
                    dragXOffset = 0.interpolated(towards: 70, amount: interpolation)
                }
            }
            .onEnded { value in
                switch model.captureMode {
                case .photo:
                    if value.predictedEndTranslation.width < -160 {
                        withAnimation(.linear(duration: 0.01)) {
                            model.captureMode = .video
                            dragXOffset = .zero
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragXOffset = .zero
                        }
                    }
                case .video:
                    if value.predictedEndTranslation.width > 160 {
                        withAnimation(.linear(duration: 0.01)) {
                            model.captureMode = .photo
                            dragXOffset = .zero
                        }
                    } else {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragXOffset = .zero
                        }
                    }
                }
            }
        
        Button {
            switch model.captureMode {
            case .photo:
                Task { await model.capturePhoto() }
            case .video:
                if model.captureActivity.isRecording {
                    Task { await model.stopRecording() }
                } else {
                    Task { await model.startRecording() }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(Color.primary, lineWidth: 2)
                    .frame(width: 70, height: 70)
                
                HStack(spacing: .zero) {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 60, height: 60)
                        .frame(width: 70, height: 70)
                        .id(0)
                    RoundedRectangle(cornerRadius: model.captureActivity.isRecording ? 8 : 22)
                        .fill(.red)
                        .animation(.smooth(duration: 0.8), value: model.captureActivity.isRecording)
                        .frame(width: model.captureActivity.isRecording ? 32 : 44,
                               height:  model.captureActivity.isRecording ? 32 : 44)
                        .frame(width: 70, height: 70)
                        .id(1)
                }
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: dragXOffset + (model.captureMode == .video ? -70 : 0))
                .frame(width: 70, height: 70, alignment: .leading)
                .clipped()
            }
            .gesture(dragGesture, isEnabled: !model.isPaused && !model.isSwitchingCameras && !model.captureActivity.isRecording)
        }
    }
}

#Preview {
    CameraActionButton()
}
