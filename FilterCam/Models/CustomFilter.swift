//
//  CustomFilter.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import Foundation
import SwiftData

@Model
final class CustomFilter: FilterGenerator {
    var id = UUID()
    var title: String {
        didSet { updatedAt = .now }
    }
    var createdAt = Date()
    var updatedAt = Date()
    var layoutIndex: Int = 0
    var filterConfiguration: [CameraFilter] {
        didSet { updatedAt = .now }
    }
    
    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), updatedAt: Date = Date(), layoutIndex: Int = 0, filterConfiguration: [CameraFilter]) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.layoutIndex = layoutIndex
        self.filterConfiguration = filterConfiguration
    }
}
