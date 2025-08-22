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
    @State private var detailViewMediumID: UUID?
    @State private var showDetailView = false
    
    @Environment(\.mediaStore) private var mediaStore
    @Environment(\.openMainApp) private var openMainApp
    @Environment(\.isCaptureExtension) private var isCaptureExtension
    
    private let columns = Array(repeating: GridItem(spacing: 0), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(model.media) { medium in
                        if let thumbnail = Thumbnail(medium) {
                            Rectangle()
                                .overlay {
                                    Image(uiImage: thumbnail.image)
                                        .resizable()
                                        .scaledToFill()
                                }
                                .overlay {
                                    if medium.type == .video {
                                        Image(systemName: "play.fill")
                                            .resizable().scaledToFit()
                                            .frame(width: 24, height: 24)
                                            .padding(16)
                                            .background(.background.secondary.opacity(0.5), in: .circle)
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(.rect)
                                .overlay(alignment: .topTrailing) {
                                    if model.isEditing {
                                        let isMarkedForDeletion = model.itemsToBeDeleted.contains(medium.id)
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
                                        if model.itemsToBeDeleted.contains(medium.id) {
                                            model.itemsToBeDeleted.remove(medium.id)
                                        } else {
                                            model.itemsToBeDeleted.insert(medium.id)
                                        }
                                    } else {
                                        detailViewMediumID = medium.id
                                        showDetailView = true
                                    }
                                }
                                .contextMenu {
                                    Button("Delete", systemImage: "trash.fill", role: .destructive) {
                                        try? model.deleteItem(medium.id)
                                    }
                                }
               
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                if isCaptureExtension || model.isEditing {
                    VStack(spacing: 28) {
                        if model.isEditing {
                            HStack(spacing: 32) {
                                Button("Cancel", systemImage: "xmark", role: .cancel) {
                                    model.itemsToBeDeleted.removeAll()
                                    model.isEditing = false
                                }
                                .foregroundStyle(Color.secondary)
                                Button("Delete", systemImage: "trash.fill", role: .destructive) {
                                    for itemID in model.itemsToBeDeleted {
                                        try? model.deleteItem(itemID)
                                    }
                                    model.itemsToBeDeleted.removeAll()
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
            .navigationDestination(isPresented: $showDetailView) {
                if let binding = Binding($detailViewMediumID) {
                    GalleryDetailView(selection: binding)
                        .environmentObject(model)
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
        @Published var media = [AnyOutputMedium]()
        @Published var itemsToBeDeleted = Set<UUID>()
        @Published var isEditing = false
        
        private var mediaStore: MediaStore!
        
        func configure(with mediaStore: MediaStore) {
            self.mediaStore = mediaStore
            refreshPhotos()
        }
        
        private func refreshPhotos() {
            media = mediaStore.media
        }
        
        @MainActor
        func deleteItem(_ itemID: UUID) throws {
            _ = try mediaStore.deleteItem(itemID)
            media.removeAll(where: { $0.id == itemID })
        }
    }
}
