//
//  Video.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import Foundation

struct Video: OutputMedium {
    var id: UUID
    var fileURL: URL
    var timestamp: Date
    var thumbnailData: Data?
    
    var data: Data {
        try! Data(contentsOf: fileURL)
    }
    
    init(id: UUID = UUID(), fileURL: URL, timestamp: Date = .now, thumbnailData: Data? = nil) {
        self.id = id
        self.fileURL = fileURL
        self.timestamp = timestamp
        self.thumbnailData = thumbnailData
    }
}
