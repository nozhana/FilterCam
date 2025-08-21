//
//  Photo.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

struct Photo: Identifiable, Codable {
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
