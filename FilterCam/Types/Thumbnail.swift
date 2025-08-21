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
}
