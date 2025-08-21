//
//  CameraInteractiveView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import SwiftUI
import AVKit

@available(iOS 17.2, *)
struct CameraInteractiveView: UIViewRepresentable {
    var onCapture: () -> Void
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let interaction = AVCaptureEventInteraction { event in
            if event.phase == .ended {
                onCapture()
            }
        }
        view.addInteraction(interaction)
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
