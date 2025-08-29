//
//  MediaStore.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import AVFoundation
import FilterCamShared
import SwiftUI

struct MediaStore {
    private let captureDirectory: URL
    
    var moviesDirectory: URL {
        let url = captureDirectory.appending(component: "movies")
        if !FileManager.default.fileExists(atPath: url.path()) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    init(appConfiguration: AppConfiguration = .shared) {
        self.captureDirectory = appConfiguration.captureDirectory
        (thumbnailStream, thumbnailContinuation) = AsyncStream.makeStream()
        refreshThumbnail()
    }
    
    let thumbnailStream: AsyncStream<Thumbnail?>
    private let thumbnailContinuation: AsyncStream<Thumbnail?>.Continuation
    
    var media: [AnyOutputMedium] {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: captureDirectory, includingPropertiesForKeys: nil),
                !contents.isEmpty else { return [] }
        var result = [AnyOutputMedium]()
        for url in contents {
            if let data = try? Data(contentsOf: url) {
                if let decoded = try? JSONDecoder().decode(Photo.self, from: data) {
                    result.append(decoded.eraseToAnyMedium())
                } else if let decoded = try? JSONDecoder().decode(Video.self, from: data) {
                    result.append(decoded.eraseToAnyMedium())
                }
            }
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
    func saveVideo(_ video: Video) throws -> URL {
        let jsonData = try JSONEncoder().encode(video)
        let videoURL = captureDirectory.appendingPathComponent(video.id.uuidString, conformingTo: .json)
        try jsonData.write(to: videoURL)
        if let thumbnailData = video.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            let thumbnail = Thumbnail(id: video.id, image: uiImage)
            thumbnailContinuation.yield(thumbnail)
        } else {
            thumbnailContinuation.yield(nil)
        }
        return videoURL
    }
    
    @discardableResult
    func delete(_ medium: AnyOutputMedium) throws -> URL {
        let mediumURL = captureDirectory.appendingPathComponent(medium.id.uuidString, conformingTo: .json)
        try FileManager.default.removeItem(at: mediumURL)
        refreshThumbnail()
        return mediumURL
    }
    
    @discardableResult
    func delete(_ id: UUID) throws -> URL {
        let mediumURL = captureDirectory.appendingPathComponent(id.uuidString, conformingTo: .json)
        guard FileManager.default.fileExists(atPath: mediumURL.path()) else {
            return mediumURL
        }
        try? FileManager.default.removeItem(at: mediumURL)
        return mediumURL
    }
    
    func refreshThumbnail() {
        if let lastMedium = media.first,
           let thumbnailData = lastMedium.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            let thumbnail = Thumbnail(id: lastMedium.id, image: uiImage)
            thumbnailContinuation.yield(thumbnail)
        } else {
            thumbnailContinuation.yield(nil)
        }
    }
    
    func wipeGallery() {
        for medium in media {
            _ = try? delete(medium)
        }
    }
}
