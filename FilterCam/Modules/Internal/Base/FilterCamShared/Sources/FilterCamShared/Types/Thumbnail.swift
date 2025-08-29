//
//  Thumbnail.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/21/25.
//

import UIKit

public struct Thumbnail: Identifiable {
    public let id: UUID
    public let image: UIImage
    
    public init(id: UUID, image: UIImage) {
        self.id = id
        self.image = image
    }
}

public extension Thumbnail {
    init?(id: UUID, sourceImage: UIImage, thumbnailSize: CGSize = .init(width: 100, height: 100)) {
        if let thumbnail = sourceImage.preparingThumbnail(of: thumbnailSize) {
            self.init(id: id, image: thumbnail)
        } else {
            return nil
        }
    }
}
