//
//  CameraViewFinder.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import AVFoundation
import SwiftUI

struct CameraViewFinder: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appConfiguration) private var appConfiguration
    @Environment(\.openMainApp) private var openMainApp
    @StateObject private var model = CameraModel()
    @Namespace private var galleryAnimation
    @State private var showGallery = false
    @State private var showOptions = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 44) {
                let showOptionsGesture = DragGesture()
                    .onEnded { value in
                        withAnimation(.smooth) {
                            if value.predictedEndTranslation.height > 100 {
                                showOptions = true
                            } else if value.predictedEndTranslation.height < -100 {
                                showOptions = false
                            }
                        }
                    }
                
                CameraPreview(session: model.session)
                    .overlay(.black.opacity(model.shouldFlashScreen ? 1 : 0))
                    .overlay(.ultraThinMaterial.opacity(model.isPaused ? 1 : 0))
                    .ignoresSafeArea(edges: .top)
                    .gesture(showOptionsGesture)
                    .onTapGesture(count: 2) {
                        Task { await model.switchCamera() }
                    }
                    .overlay(alignment: .top) {
                        if showOptions {
                            CameraOptionsView()
                                .environmentObject(model)
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .safeAreaInset(edge: .bottom, spacing: 8) {
                                    Button {
                                        withAnimation(.smooth) {
                                            showOptions = false
                                        }
                                    } label: {
                                        Image(systemName: "chevron.up")
                                            .font(.caption.weight(.light))
                                            .foregroundStyle(.yellow)
                                            .padding(12)
                                            .background(.background.secondary.opacity(0.5), in: .circle)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.bottom, 8)
                                }
                                .background(.ultraThinMaterial)
                                .transition(.move(edge: .top).combined(with: .offset(y: -64)))
                        } else {
                            Button {
                                withAnimation(.smooth) {
                                    showOptions = true
                                }
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.caption.weight(.light))
                                    .foregroundStyle(.yellow)
                                    .padding(12)
                                    .background(.background.secondary.opacity(0.5), in: .circle)
                            }
                            .buttonStyle(.plain)
                            .transition(.move(edge: .top).combined(with: .offset(y: -64)))
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if !openMainApp.isNoop {
                            Button {
                                Task { try await openMainApp() }
                            } label: {
                                Label("Open App", systemImage: "arrow.up.right")
                                    .font(.caption.weight(.light).smallCaps())
                                    .foregroundStyle(.yellow)
                                    .padding(10)
                                    .background(.background.secondary.opacity(0.4), in: .rect(cornerRadius: 12, style: .continuous))
                            }
                            .padding(.trailing, 12)
                            .padding(.bottom, 16)
                        }
                    }
                HStack {
                        Button {
                            showGallery = true
                        } label: {
                            if let thumbnail = model.thumbnail {
                                Image(uiImage: thumbnail.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(.rect(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.background.secondary)
                                    .frame(width: 64, height: 64)
                                    .overlay {
                                        Image(systemName: "photo.stack.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 28, height: 28)
                                            .foregroundStyle(Color.secondary)
                                    }
                            }
                        }
                        .backport.matchedTransitionSource(id: "gallery", in: galleryAnimation)
                    Spacer()
                    Button {
                        Task { await model.capturePhoto() }
                    } label: {
                        Circle()
                            .fill(.white)
                            .frame(width: 68, height: 68)
                            .background(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                                    .padding(-4)
                            )
                    }
                    Spacer()
                    Button {
                        Task { await model.switchCamera() }
                    } label: {
                        Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                            .foregroundStyle(.white)
                            .padding(12)
                            .frame(width: 64, height: 64)
                            .background(.gray.tertiary, in: .circle)
                    }
                }
                .safeAreaPadding(.horizontal, 16)
                .safeAreaPadding(.bottom, 24)
            }
        }
        .backport.onCameraCaptureEvent {
            Task {
                await model.capturePhoto()
            }
        }
        .sheet(isPresented: $showGallery) {
            GalleryView(animation: galleryAnimation)
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else {
                await model.pauseStream()
                return
            }
            guard !model.isPaused else {
                await model.unpauseStream()
                return
            }
            guard model.status == .unknown else {
                return
            }
            model.configure(with: appConfiguration)
            await model.start()
        }
        .task {
            if model.isPaused {
                await model.unpauseStream()
                return
            }
        }
        .onDisappear {
            Task {
                await model.pauseStream()
            }
        }
    }
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
