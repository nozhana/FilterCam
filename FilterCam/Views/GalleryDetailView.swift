//
//  GalleryDetailView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import AVKit
import Combine
import SwiftUI

struct GalleryDetailView: View {
    @Binding var selection: UUID
    
    @EnvironmentObject private var model: GalleryView.Model
    
    var body: some View {
        ZStack {
            MediaPager(model: .init(selection: _selection, media: $model.media))
            VStack(spacing: .zero) {
                if let selectedMedium = model.media.first(where: { $0.id == selection }) {
                    HStack(alignment: .firstTextBaseline, spacing: .zero) {
                        Text(selectedMedium.type == .video ? "Video" : "Photo")
                            .font(.headline.bold())
                        Spacer()
                        Text(selectedMedium.timestamp, format: .dateTime.month(.abbreviated).day())
                            .font(.subheadline)
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            try? model.deleteItem(selection)
                        }
                    }
                }
            }
            .safeAreaPadding(.horizontal, 16)
            .safeAreaPadding(.vertical, 10)
        }
    }
}

#Preview {
    GalleryDetailView(selection: .constant(UUID()))
        .environmentObject(GalleryView.Model())
}

private struct MediaPager: View {
    @ObservedObject var model: Model
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: .zero) {
                    ForEach(model.media) { medium in
                        Group {
                            switch medium.type {
                            case .photo:
                                if let uiImage = UIImage(data: medium.data) {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFit()
                                }
                            case .video:
                                if let video = medium.as(Video.self) {
                                    let player = AVPlayer(url: video.fileURL)
                                    CustomVideoPlayer(player: player)
                                        .task(id: model.selection) {
                                            if model.selection == video.id {
                                                player.play()
                                            } else {
                                                player.pause()
                                            }
                                        }
                                }
                            }
                        }
                        .id(medium.id)
                        .containerRelativeFrame(.horizontal)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .backport.alwaysByOne))
            .scrollPosition(id: Binding(model.$selection), anchor: .leading)
            .task {
                try? await Task.sleep(for: .seconds(0.1))
                proxy.scrollTo(model.selection, anchor: .leading)
            }
        }
        // TabView(selection: model.$selection) {
        //     ForEach(model.media) { medium in
        //         switch medium.type {
        //         case .photo:
        //             if let uiImage = UIImage(data: medium.data) {
        //                 Image(uiImage: uiImage)
        //                     .resizable().scaledToFit()
        //                     .tag(medium.id)
        //             }
        //         case .video:
        //             let video = medium.as(Video.self)!
        //             let player = AVPlayer(url: video.fileURL)
        //             CustomVideoPlayer(player: player, stateStream: videoPlayerStateStream)
        //                 .onGeometryChange(for: CGSize.self, of: \.size) { size in
        //                     model.containerSize = size
        //                 }
        //                 .aspectRatio(model.aspectRatio, contentMode: .fit)
        //                 .tag(medium.id)
        //         }
        //     }
        // }
        // .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

private extension MediaPager {
    final class Model: ObservableObject {
        @Binding var selection: UUID
        @Binding var media: [AnyOutputMedium]
        
        init(selection: Binding<UUID>, media: Binding<[AnyOutputMedium]>) {
            self._selection = selection
            self._media = media
        }
    }
}

private struct CustomVideoPlayer: UIViewRepresentable {
    final class PreviewLayerView: UIView {
        override class var layerClass: AnyClass {
            AVPlayerLayer.self
        }
        
        private var playerLayer: AVPlayerLayer {
            layer as! AVPlayerLayer
        }
        
        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue }
        }
    }
    
    final class PlaybackView: UIView {
        private var previewView: PreviewLayerView!
        private var playPauseButton: UIButton!
        
        var player: AVPlayer? {
            get { previewView.player }
            set { previewView.player = newValue }
        }
        
        init() {
            let previewView = PreviewLayerView()
            self.previewView = previewView
            let button = UIButton()
            self.playPauseButton = button
            
            let frame = UIScreen.main.bounds.insetBy(dx: .zero, dy: 64)
            
            previewView.frame = frame
            
            super.init(frame: frame)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init?(coder:) not implemented")
        }
        
        private let playButtonImage = {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 44, weight: .bold)
            let image = UIImage(systemName: "play.fill", withConfiguration: configuration)!
            return image
        }()
        private let pauseButtonImage = {
            let configuration = UIImage.SymbolConfiguration.init(pointSize: 44, weight: .bold)
            let image = UIImage(systemName: "pause.fill", withConfiguration: configuration)!
            return image
        }()
        
        override func didMoveToSuperview() {
            self.layer.addSublayer(previewView.layer)
            self.addSubview(previewView)
            playPauseButton.setImage(playButtonImage, for: .normal)
            playPauseButton.layer.cornerRadius = 12
            playPauseButton.setTitleColor(.white, for: .normal)
            playPauseButton.tintColor = .white
            self.addSubview(playPauseButton)
            let frame = UIScreen.main.bounds.insetBy(dx: .zero, dy: 64)
            playPauseButton.frame = .init(x: frame.width / 2 - 100,
                                 y: frame.height / 2 - 100,
                                 width: 200, height: 200)
            playPauseButton.addTarget(self, action: #selector(didTapPlayPauseButton), for: .touchUpInside)
            super.didMoveToSuperview()
        }
        
        @objc private func didTapPlayPauseButton(sender: UIButton) {
            if previewView.player?.rate == .zero || previewView.player?.currentItem == nil || previewView.player == nil {
                previewView.player?.play()
                playPauseButton.setImage(pauseButtonImage, for: .normal)
            } else {
                previewView.player?.pause()
                playPauseButton.setImage(playButtonImage, for: .normal)
            }
        }
    }
    
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlaybackView {
        let view = PlaybackView()
        view.player = player
        return view
    }
    
    func updateUIView(_ uiView: PlaybackView, context: Context) {}
    
    fileprivate func play(videoAt url: URL? = nil) {
        var shouldStopAccessingSecureResource = false
        defer {
            if shouldStopAccessingSecureResource {
                url?.stopAccessingSecurityScopedResource()
            }
        }
        if let url {
            if url.startAccessingSecurityScopedResource() {
                shouldStopAccessingSecureResource = true
            }
            player.replaceCurrentItem(with: .init(url: url))
        }
        player.play()
    }
    
    fileprivate func pause() {
        player.pause()
    }
    
    fileprivate func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
    }
}

private enum VideoPlayerState {
    case idle, playing(URL? = nil)
    
    static let playing = playing()
}
