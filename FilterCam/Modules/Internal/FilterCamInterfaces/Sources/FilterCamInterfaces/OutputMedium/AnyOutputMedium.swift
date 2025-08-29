//
//  AnyOutputMedium.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import UIKit

public enum OutputMediumType {
    case photo, video
}

public struct AnyOutputMedium: OutputMedium {
    private let anyMedium: any OutputMedium
    public var type: OutputMediumType
    public var id: UUID { anyMedium.id }
    public var data: Data { anyMedium.data }
    public var timestamp: Date { anyMedium.timestamp }
    
    public var thumbnailData: Data? {
        if let photo = anyMedium as? Photo,
           let uiImage = UIImage(data: photo.data),
           let thumbnail = uiImage.preparingThumbnail(of: .init(width: 100, height: 100)),
           let pngData = thumbnail.pngData() {
            return pngData
        } else if let video = anyMedium as? Video {
            return video.thumbnailData
        } else {
            return nil
        }
    }
    
    public func `as`<M>(_ mediumType: M.Type) -> M? where M: OutputMedium {
        anyMedium as? M
    }
    
    public init(_ medium: any OutputMedium) {
        if let anyMedium = medium as? AnyOutputMedium {
            self = anyMedium
            return
        } else {
            self.anyMedium = medium
        }
        self.type = medium is Video ? .video : .photo
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let video = try? container.decode(Video.self) {
            self.anyMedium = video
            self.type = .video
        } else if let photo = try? container.decode(Photo.self) {
            self.anyMedium = photo
            self.type = .photo
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown output medium")
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(anyMedium)
    }
}

public extension OutputMedium {
    func eraseToAnyMedium() -> AnyOutputMedium {
        .init(self)
    }
}
