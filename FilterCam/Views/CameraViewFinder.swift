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
    @Environment(\.isCaptureExtension) private var isCaptureExtension
    
    @StateObject private var model = CameraModel()
    
    @Namespace private var galleryAnimation
    
    @State private var showGallery = false
    @State private var showOptions = false
    @State private var showSettings = false
    
    @AppStorage(UserDefaultsKey.cameraSwitchRotationEffect.rawValue, store: .shared)
    private var rotateCamera = true
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
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
                
                CameraPreview(session: model.session) { devicePoint, layerPoint in
                    Task {
                        await model.focusAndExpose(on: devicePoint, layerPoint: layerPoint)
                    }
                }
                .if(rotateCamera) { conditionalContent in
                    conditionalContent
                        .phaseAnimator([0, 1], trigger: model.isSwitchingCameras) { content, phase in
                            content
                                .rotation3DEffect(.degrees((model.isSwitchingCameras && phase == 1) ? 180 : 0), axis: (0, 1, 0), anchor: .center, perspective: 1.2)
                        } animation: { phase in
                            phase == 0 ? .easeOut(duration: 0.2) : .linear(duration: 0.01)
                        }
                }
                .overlay {
                    if let focusPoint = model.focusPoint {
                        TargetShape()
                            .foregroundStyle(.yellow)
                            .frame(width: 100, height: 100)
                            .position(focusPoint)
                    }
                }
                .overlay(.black.opacity(model.shouldFlashScreen ? 1 : 0))
                .overlay(.black.opacity(model.isSwitchingCameras ? 1 : 0))
                .overlay(.ultraThinMaterial.opacity(model.isPaused ? 1 : 0))
                .ignoresSafeArea(edges: .top)
                .animation(.snappy) { content in
                    content
                        .aspectRatio(1 / model.aspectRatio.rawValue, contentMode: .fit)
                        .offset(y: model.aspectRatio.previewOffsetY)
                }
                .gesture(showOptionsGesture)
                .onTapGesture(count: 2) {
                    Task { await model.switchCamera() }
                }
                VStack(spacing: 44) {
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
                    if model.captureActivity.isRecording {
                        let duration = Duration.seconds(model.captureActivity.duration)
                        Text(duration, format: .time(pattern: .minuteSecond(padMinuteToLength: 2, fractionalSecondsLength: 2)))
                            .font(.callout.weight(.light).monospacedDigit())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(.red, in: .rect(cornerRadius: 12, style: .continuous))
                            .transition(.move(edge: .top).combined(with: .blurReplace))
                    }
                    Spacer()
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
                        CameraActionButton()
                            .environmentObject(model)
                        Spacer()
                        Button {
                            Task { await model.switchCamera() }
                        } label: {
                            Image(systemName: "arrow.trianglehead.2.counterclockwise.rotate.90")
                                .foregroundStyle(.white.opacity(model.isSwitchingCameras ? 0.4 : 1))
                                .padding(12)
                                .frame(width: 64, height: 64)
                                .background(.gray.tertiary, in: .circle)
                        }
                        .disabled(model.isSwitchingCameras)
                        .overlay {
                            if model.isSwitchingCameras {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .frame(width: 44, height: 44)
                                    .transition(.scale.combined(with: .blurReplace))
                            }
                        }
                    }
                    .safeAreaPadding(.horizontal, 16)
                    .safeAreaPadding(.vertical, 24)
                    .background(.background.opacity(0.6))
                    .overlay(alignment: .top) {
                        Group {
                            if isCaptureExtension {
                                Button {
                                    Task { try await openMainApp() }
                                } label: {
                                    Label("Open App", systemImage: "arrow.up.right")
                                        .font(.caption2.smallCaps().weight(.light))
                                        .foregroundStyle(.yellow.gradient)
                                        .padding(12)
                                        .background(.background.secondary.opacity(0.5), in: .rect(cornerRadius: 12, style: .continuous))
                                }
                            } else {
                                Button {
                                    showSettings = true
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.secondary)
                                        .padding(12)
                                        .background(.background.secondary.opacity(0.5), in: .circle)
                                }
                                .padding(.leading, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .offset(y: -64)
                    }
                }
            }
            .sheet(isPresented: $showGallery) {
                GalleryView(animation: galleryAnimation)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .backport.onCameraCaptureEvent {
            Task {
                await model.capturePhoto()
            }
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
        
        var onFocus: ((_ devicePoint: CGPoint, _ layerPoint: CGPoint) -> Void)!
        
        override func didMoveToSuperview() {
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(focus))
            addGestureRecognizer(tapRecognizer)
            super.didMoveToSuperview()
        }
        
        @objc private func focus(sender: UITapGestureRecognizer) {
            guard sender.state == .ended else { return }
            let layerPoint = sender.location(ofTouch: 0, in: self)
            let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: layerPoint)
            onFocus(devicePoint, layerPoint)
        }
    }
    
    let session: AVCaptureSession
    let onFocus: (_ devicePoint: CGPoint, _ layerPoint: CGPoint) -> Void
    
    init(session: AVCaptureSession, onFocus: @escaping (_ devicePoint: CGPoint, _ layerPoint: CGPoint) -> Void) {
        self.session = session
        self.onFocus = onFocus
    }
    
    func makeUIView(context: Context) -> some UIView {
        let view = PreviewView()
        view.onFocus = onFocus
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
