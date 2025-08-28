//
//  Photo.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import FilterCamBase
import UIKit

struct Photo: OutputMedium {
    let id: UUID
    let data: Data
    let timestamp: Date
    let isProxy: Bool
    
    init(id: UUID = UUID(), data: Data, timestamp: Date = .now, isProxy: Bool = false) {
        self.id = id
        self.data = data
        self.timestamp = timestamp
        self.isProxy = isProxy
    }
}

extension Photo {
    func cropped(to ratio: CGFloat) -> Photo {
        guard let uiImage = UIImage(data: data),
              let croppedImage = uiImage.cropped(to: ratio),
              let pngData = croppedImage.pngData() else { return self }
        return Photo(id: id, data: pngData, timestamp: timestamp, isProxy: isProxy)
    }
}
