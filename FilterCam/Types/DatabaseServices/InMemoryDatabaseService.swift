//
//  InMemoryDatabaseService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import SwiftData
import SwiftUI

final class InMemoryDatabaseService: DatabaseService {
    let container: ModelContainer
    
    static let shared = InMemoryDatabaseService()
    
    init(groupContainer: ModelConfiguration.GroupContainer = .automatic) {
        let schema = Schema([
            CustomFilter.self
        ])
        let configuration = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to initialize in-memory model container: \(error)")
        }
    }
}

extension DatabaseService where Self == InMemoryDatabaseService {
    static var inMemory: InMemoryDatabaseService { .shared }
    
    static func inMemory(groupContainer: ModelConfiguration.GroupContainer = .automatic) -> InMemoryDatabaseService {
        .init(groupContainer: groupContainer)
    }
}
