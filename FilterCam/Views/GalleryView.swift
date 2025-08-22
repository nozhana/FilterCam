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
    @Environment(\.isCaptureExtension) private var isCaptureExtension
    
    private let columns = Array(repeating: GridItem(spacing: 0), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(model.photos) { photo in
                        if let thumbnail = Thumbnail(id: photo.id, sourceImage: photo.image) {
                            Rectangle()
                                .overlay {
                                    Image(uiImage: thumbnail.image)
                                        .resizable()
                                        .scaledToFill()
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(.rect)
                                .overlay(alignment: .topTrailing) {
                                    if model.isEditing {
                                        let isMarkedForDeletion = model.photosToBeDeleted.contains(photo.id)
                                        Image(systemName: isMarkedForDeletion ? "checkmark.circle.fill" : "circle")
                                            .font(.title2.bold())
                                            .contentTransition(.symbolEffect)
                                            .animation(.linear(duration: 0.1), value: isMarkedForDeletion)
                                            .padding(14)
                                            .foregroundStyle(isMarkedForDeletion ? Color.accentColor : Color.secondary)
                                    }
                                }
                                .onTapGesture {
                                    if model.isEditing {
                                        if model.photosToBeDeleted.contains(photo.id) {
                                            model.photosToBeDeleted.remove(photo.id)
                                        } else {
                                            model.photosToBeDeleted.insert(photo.id)
                                        }
                                    }
                                }
                                .contextMenu {
                                    Button("Delete", systemImage: "trash.fill", role: .destructive) {
                                        try? model.deletePhoto(photo)
                                    }
                                } preview: {
                                    Image(uiImage: photo.image)
                                        .resizable()
                                        .scaledToFit()
                                }

                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                if isCaptureExtension || model.isEditing {
                    VStack(spacing: 16) {
                        if model.isEditing {
                            HStack(spacing: 24) {
                                Button("Cancel", systemImage: "xmark", role: .cancel) {
                                    model.photosToBeDeleted.removeAll()
                                    model.isEditing = false
                                }
                                Button("Delete", systemImage: "trash.fill", role: .destructive) {
                                    for photoID in model.photosToBeDeleted {
                                        try? model.deletePhoto(photoID)
                                    }
                                    model.photosToBeDeleted.removeAll()
                                }
                            }
                            .font(.caption.smallCaps().bold())
                        }
                        if isCaptureExtension {
                            Button {
                                Task { try await openMainApp() }
                            } label: {
                                Label("Open App to see all your media", systemImage: "arrow.up.right")
                                    .font(.caption.smallCaps().weight(.light))
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle("Edit", systemImage: "pencil", isOn: $model.isEditing)
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
        @Published fileprivate var photos = [LoadedPhoto]()
        @Published var photosToBeDeleted = Set<UUID>()
        @Published var isEditing = false
        
        private var mediaStore: MediaStore!
        
        func configure(with mediaStore: MediaStore) {
            self.mediaStore = mediaStore
            refreshPhotos()
        }
        
        private func refreshPhotos() {
            photos = mediaStore.photos.compactMap(LoadedPhoto.init)
        }
        
        @MainActor
        fileprivate func deletePhoto(_ photo: LoadedPhoto) throws {
            _ = try mediaStore.deletePhoto(photo.id)
            photos.removeAll { $0.id == photo.id }
        }
        
        @MainActor
        func deletePhoto(_ photoID: UUID) throws {
            _ = try mediaStore.deletePhoto(photoID)
            photos.removeAll { $0.id == photoID }
        }
    }
}

private struct LoadedPhoto: Identifiable {
    var id: UUID
    var image: UIImage
    var timestamp: Date
    var isProxy: Bool
}

extension LoadedPhoto {
    init?(_ photo: Photo) {
        guard let image = UIImage(data: photo.data) else {
            return nil
        }
        self.id = photo.id
        self.image = image
        self.timestamp = photo.timestamp
        self.isProxy = photo.isProxy
    }
}
