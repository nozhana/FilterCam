//
//  GalleryView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/21/25.
//

import simd
import SwiftUI

struct GalleryView: View {
    var animation: Namespace.ID?
    
    @StateObject private var model = Model()
    
    @Environment(\.mediaStore) private var mediaStore
    @Environment(\.openMainApp) private var openMainApp
    
    private let columns = Array(repeating: GridItem(spacing: 0), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(model.photos) { photo in
                        if let uiImage = UIImage(data: photo.data),
                           let thumbnail = Thumbnail(id: photo.id, sourceImage: uiImage) {
                            Rectangle()
                                .overlay {
                                    Image(uiImage: thumbnail.image)
                                        .resizable()
                                        .scaledToFill()
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(.rect)
                                .contextMenu {
                                    Button("Delete", systemImage: "trash.fill", role: .destructive) {
                                        try? model.deletePhoto(photo)
                                    }
                                } preview: {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                }

                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                if !openMainApp.isNoop {
                    Button {
                        Task { try await openMainApp() }
                    } label: {
                        Label("Open App to see all your media", systemImage: "arrow.up.right")
                            .font(.caption.smallCaps().weight(.light))
                            .foregroundStyle(.yellow)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                    }
                }
            }
            .navigationTitle("Gallery")
        }
        .ifLet(animation) { content, animation in
            content
                .backport.navigationTransitionZoom(sourceID: "gallery", in: animation)
        }
        .onAppear {
            model.configure(with: mediaStore)
        }
    }
}

#Preview {
    GalleryView()
        .environmentObject(GalleryView.Model())
}

extension GalleryView {
    final class Model: ObservableObject {
        @Published private(set) var photos = [Photo]()
        
        private var mediaStore: MediaStore!
        
        func configure(with mediaStore: MediaStore) {
            self.mediaStore = mediaStore
            refreshPhotos()
        }
        
        private func refreshPhotos() {
            photos = mediaStore.photos
        }
        
        @MainActor
        func deletePhoto(_ photo: Photo) throws {
            _ = try mediaStore.deletePhoto(photo)
            photos.removeAll(where: { $0.id == photo.id })
        }
    }
}
