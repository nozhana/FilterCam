//
//  DatabaseService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import SwiftData
import SwiftUI

public protocol DatabaseService {
    init(groupContainer: ModelConfiguration.GroupContainer)
    var container: ModelContainer { get }
    @MainActor
    func save(_ model: any PersistentModel) throws
    @MainActor
    func delete(_ model: any PersistentModel) throws
    @MainActor
    func fetch<T>(_ model: T.Type, sortDescriptors: [SortDescriptor<T>], predicate: Predicate<T>?) throws -> T? where T: PersistentModel
    @MainActor
    func list<T>(_ model: T.Type, sortDescriptors: [SortDescriptor<T>], predicate: Predicate<T>?, fetchCount: Int?) throws -> [T] where T: PersistentModel
    @MainActor
    func count<T>(_ model: T.Type, predicate: Predicate<T>?) throws -> Int where T: PersistentModel
}

public extension DatabaseService {
    @MainActor
    func save(_ model: any PersistentModel) throws {
        container.mainContext.insert(model)
        try container.mainContext.save()
    }
    
    @MainActor
    func delete(_ model: any PersistentModel) throws {
        container.mainContext.delete(model)
        try container.mainContext.save()
    }
    
    @MainActor
    func save(_ models: [any PersistentModel]) throws {
        for model in models {
            try save(model)
        }
    }
    
    @MainActor
    func delete(_ models: [any PersistentModel]) throws {
        for model in models {
            try delete(model)
        }
    }
    
    @MainActor
    func fetch<T>(_ model: T.Type = T.self, sortDescriptors: [SortDescriptor<T>] = [], predicate: Predicate<T>? = nil) throws -> T? where T: PersistentModel {
        try list(T.self, sortDescriptors: sortDescriptors, predicate: predicate, fetchCount: 1).first
    }
    
    @MainActor
    func list<T>(_ model: T.Type = T.self, sortDescriptors: [SortDescriptor<T>] = [], predicate: Predicate<T>? = nil, fetchCount: Int? = nil) throws -> [T] where T: PersistentModel {
        var descriptor = FetchDescriptor(predicate: predicate, sortBy: sortDescriptors)
        descriptor.fetchLimit = fetchCount
        return try container.mainContext.fetch(descriptor)
    }
    
    @MainActor
    func count<T>(_ model: T.Type = T.self, predicate: Predicate<T>? = nil) throws -> Int where T: PersistentModel {
        let descriptor = FetchDescriptor(predicate: predicate)
        return try container.mainContext.fetchCount(descriptor)
    }
    
    @MainActor
    func min<M, T>(_ model: M.Type = M.self, by keyPath: KeyPath<M, T>) throws -> M? where M: PersistentModel, T: Comparable {
        try fetch(sortDescriptors: [.init(keyPath)])
    }
    
    @MainActor
    func max<M, T>(_ model: M.Type = M.self, by keyPath: KeyPath<M, T>) throws -> M? where M: PersistentModel, T: Comparable {
        try fetch(sortDescriptors: [.init(keyPath, order: .reverse)])
    }
}

public extension View {
    func databaseContainer(_ database: some DatabaseService = .default) -> some View {
        self
            .modelContainer(database.container)
            .environment(\.database, database)
    }
}
