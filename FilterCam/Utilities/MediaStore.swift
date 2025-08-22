//
//  MediaStore.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import SwiftUI

struct MediaStore {
    private let captureDirectory: URL
    
    init(appConfiguration: AppConfiguration = .shared) {
        self.captureDirectory = appConfiguration.captureDirectory
        (thumbnailStream, thumbnailContinuation) = AsyncStream.makeStream()
        refreshThumbnail()
    }
    
    let thumbnailStream: AsyncStream<Thumbnail?>
    private let thumbnailContinuation: AsyncStream<Thumbnail?>.Continuation
    
    var photos: [Photo] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: captureDirectory, includingPropertiesForKeys: nil),
                !contents.isEmpty else { return [] }
        var result = [Photo]()
        for url in contents {
            guard let data = try? Data(contentsOf: url),
                  let decoded = try? JSONDecoder().decode(Photo.self, from: data) else { continue }
            result.append(decoded)
        }
        result.sort(using: KeyPathComparator(\.timestamp, order: .reverse))
        return result
    }
    
    static let shared = MediaStore()
    
#if DEBUG
    static let preview = MediaStore(appConfiguration: .preview)
#endif
    
    @discardableResult
    func savePhoto(_ photo: Photo) throws -> URL {
        let jsonData = try JSONEncoder().encode(photo)
        let photoURL = captureDirectory.appendingPathComponent(photo.id.uuidString, conformingTo: .json)
        try jsonData.write(to: photoURL)
        if let uiImage = UIImage(data: photo.data),
           let thumbnail = Thumbnail(id: photo.id, sourceImage: uiImage) {
            thumbnailContinuation.yield(thumbnail)
        } else {
            thumbnailContinuation.yield(nil)
        }
        return photoURL
    }
    
    @discardableResult
    func deletePhoto(_ photoID: UUID) throws -> URL {
        let photoURL = captureDirectory.appendingPathComponent(photoID.uuidString, conformingTo: .json)
        try FileManager.default.removeItem(at: photoURL)
        refreshThumbnail()
        return photoURL
    }
    
    func refreshThumbnail() {
        if let lastPhoto = photos.first,
           let image = UIImage(data: lastPhoto.data),
           let thumbnail = Thumbnail(id: lastPhoto.id, sourceImage: image) {
            thumbnailContinuation.yield(thumbnail)
        } else {
            thumbnailContinuation.yield(nil)
        }
    }
}

extension EnvironmentValues {
#if DEBUG
    @Entry var mediaStore = ProcessInfo.isRunningPreviews ? MediaStore.preview : .shared
#else
    @Entry var mediaStore = MediaStore.shared
#endif
}
