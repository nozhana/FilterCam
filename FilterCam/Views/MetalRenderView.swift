//
//  MetalRenderView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

import GPUImage
import SwiftUI
import MetalKit

struct MetalRenderView: View {
    var previewTarget: MetalPreviewTarget
    
    var body: some View {
        GeometryReader { geometry in
            MetalView(view: previewTarget.renderView, frame: geometry.frame(in: .global))
                .aspectRatio(previewTarget.aspectRatio, contentMode: .fill)
        }
    }
}

private struct MetalView: UIViewRepresentable {
    var view: MTKView
    var frame: CGRect
    
    func makeUIView(context: Context) -> MTKView {
        view.frame = frame
        return view
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
}
