//
//  DefaultDatabaseService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import FilterCamInterfaces
import SwiftData
import SwiftUI

final class DefaultDatabaseService: DatabaseService {
    let container: ModelContainer
    
    static let shared = DefaultDatabaseService()
    
    init(groupContainer: ModelConfiguration.GroupContainer = .automatic) {
        let schema = Schema([
            CustomFilter.self
        ])
        let configuration = ModelConfiguration(schema: schema, groupContainer: groupContainer)
        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to initialize default model container: \(error)")
        }
    }
}

extension DatabaseService where Self == DefaultDatabaseService {
    static var `default`: DefaultDatabaseService { .shared }
    
    static func `default`(groupContainer: ModelConfiguration.GroupContainer = .automatic) -> DefaultDatabaseService {
        .init(groupContainer: groupContainer)
    }
}
