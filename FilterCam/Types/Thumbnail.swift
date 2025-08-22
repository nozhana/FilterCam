//
//  Thumbnail.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/21/25.
//

import UIKit

struct Thumbnail: Identifiable {
    let id: UUID
    let image: UIImage
}

extension Thumbnail {
    init?(id: UUID, sourceImage: UIImage, thumbnailSize: CGSize = .init(width: 100, height: 100)) {
        if let thumbnail = sourceImage.preparingThumbnail(of: thumbnailSize) {
            self.init(id: id, image: thumbnail)
        } else {
            return nil
        }
    }
    
    init?(_ medium: some OutputMedium) {
        if let photo = medium as? Photo,
           let uiImage = UIImage(data: photo.data) {
            self.init(id: photo.id, sourceImage: uiImage)
        } else if let video = medium as? Video,
                  let thumbnailData = video.thumbnailData,
                  let thumbnail = UIImage(data: thumbnailData) {
            self.init(id: video.id, image: thumbnail)
        } else if let anyMedium = medium as? AnyOutputMedium,
                  let thumbnailData = anyMedium.thumbnailData,
                  let uiImage = UIImage(data: thumbnailData) {
            self.init(id: anyMedium.id, image: uiImage)
        } else {
            return nil
        }
    }
}
