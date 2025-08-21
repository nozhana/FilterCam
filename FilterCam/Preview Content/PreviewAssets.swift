//
//  PreviewAssets.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/21/25.
//

import UIKit

enum PreviewAssets {
    static let initialPhotos: [Photo] = [
        Photo(data: UIImage(resource: .media1).pngData()!),
        Photo(data: UIImage(resource: .media2).pngData()!)
    ]
}
