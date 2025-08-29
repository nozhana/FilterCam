//
//  GalleryView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/21/25.
//

import FilterCamBase
import FilterCamMacros
import FilterCamShared
import simd
import SwiftUI

@Provider(\.mediaStore)
struct GalleryView: View {
    private var animation: Namespace.ID?
    
    init(animation: Namespace.ID? = nil) {
        self.animation = animation
    }
    
    @StateObject private var model = Model()
    
    @Environment(\.openMainApp) private var openMainApp
    
    private let columns = Array(repeating: GridItem(spacing: 0), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(model.media) { medium in
                        if let thumbnailData = medium.thumbnailData,
                           let uiImage = UIImage(data: thumbnailData) {
                            let thumbnail = Thumbnail(id: medium.id, image: uiImage)
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
                                        try? model.delete(medium)
                                    }
                                } preview: {
                                    if let photo = medium.as(Photo.self),
                                       let uiImage = UIImage(data: photo.data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                    } else {
                                        // TODO: Add video preview support
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                    }
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
        @Published var media = [AnyOutputMedium]()
        
        private var mediaStore: MediaStore!
        
        func configure(with mediaStore: MediaStore) {
            self.mediaStore = mediaStore
            refreshMedia()
        }
        
        private func refreshMedia() {
            media = mediaStore.media
        }
        
        @MainActor
        func delete(_ medium: AnyOutputMedium) throws {
            try mediaStore.delete(medium)
            media.removeAll(where: { $0.id == medium.id })
        }
        
        @MainActor
        func delete(_ id: UUID) throws {
            try mediaStore.delete(id)
        }
    }
}
