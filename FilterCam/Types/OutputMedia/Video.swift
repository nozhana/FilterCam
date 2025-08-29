//
//  Video.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import FilterCamInterfaces
import Foundation

struct Video: OutputMedium {
    var id: UUID
    var fileURL: URL
    var timestamp: Date
    var thumbnailData: Data?
    
    var data: Data {
        var shouldStopAccessingSecureResource = false
        defer {
            if shouldStopAccessingSecureResource {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }
        if fileURL.startAccessingSecurityScopedResource() {
            shouldStopAccessingSecureResource = true
        }
        return try! Data(contentsOf: fileURL)
    }
    
    init(id: UUID = UUID(), fileURL: URL, timestamp: Date = .now, thumbnailData: Data? = nil) {
        if let inferredID = UUID(uuidString: fileURL.lastPathComponent) {
            self.id = inferredID
        } else {
            self.id = id
        }
        self.fileURL = fileURL
        self.timestamp = timestamp
        self.thumbnailData = thumbnailData
    }
}
