//
//  MediaStore.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/20/25.
//

import UIKit

struct MediaStore {
    private let captureDirectory: URL
    
    let moviesDirectory: URL
    
    init(appConfiguration: AppConfiguration = .shared) {
        self.captureDirectory = appConfiguration.captureDirectory
        self.moviesDirectory = appConfiguration.moviesDirectory
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
            guard let data = try? Data(contentsOf: url) else { continue }
            if let video = try? JSONDecoder().decode(Video.self, from: data) {
                result.append(video.eraseToAnyMedium())
            } else if let photo = try? JSONDecoder().decode(Photo.self, from: data) {
                result.append(photo.eraseToAnyMedium())
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
    func deleteItem(_ itemID: UUID) throws -> URL {
        let itemURL = captureDirectory.appendingPathComponent(itemID.uuidString, conformingTo: .json)
        try FileManager.default.removeItem(at: itemURL)
        let possibleVideoFileURL = moviesDirectory.appendingPathComponent(itemID.uuidString, conformingTo: .mpeg4Movie)
        try? FileManager.default.removeItem(at: possibleVideoFileURL)
        refreshThumbnail()
        return itemURL
    }
    
    @discardableResult
    func saveVideo(_ video: Video) throws -> URL {
        let jsonData = try JSONEncoder().encode(video)
        let videoURL = captureDirectory.appendingPathComponent(video.id.uuidString, conformingTo: .json)
        try? FileManager.default.removeItem(at: videoURL)
        try jsonData.write(to: videoURL)
        refreshThumbnail()
        return videoURL
    }
    
    func refreshThumbnail() {
        if let lastMedium = media.first,
           let thumbnailData = lastMedium.thumbnailData,
           let thumbnailImage = UIImage(data: thumbnailData) {
            let thumbnail = Thumbnail(id: lastMedium.id, image: thumbnailImage)
            thumbnailContinuation.yield(thumbnail)
        } else {
            thumbnailContinuation.yield(nil)
        }
    }
}
