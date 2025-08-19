//
//  CameraViewFinder.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import SwiftUI

struct CameraViewFinder: View {
    @Environment(\.appConfiguration) private var appConfiguration
    @StateObject private var model = CameraModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                CameraPreview(session: model.session)
                    .overlay(.black.opacity(model.shouldFlashScreen ? 1 : 0))
                HStack {
                    Spacer()
                    Button {
                        Task {
                            await model.capturePhoto()
                        }
                    } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 86, height: 86)
                    }
                    Spacer()
                }
            }
        }
        .colorScheme(.dark)
        .task {
            model.configure(with: appConfiguration)
            await model.start()
        }
    }
}

#Preview {
    CameraViewFinder()
}

private struct CameraPreview: UIViewRepresentable {
    final class PreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
    
    init(session: AVCaptureSession) {
        self.session = session
    }
    
    func makeUIView(context: Context) -> some UIView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
