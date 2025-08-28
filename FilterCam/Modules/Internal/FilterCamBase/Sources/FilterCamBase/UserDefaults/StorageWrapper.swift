//
//  StorageWrapper.swift
//  FilterCamBase
//
//  Created by Nozhan A. on 8/28/25.
//

import SwiftUI

@propertyWrapper
public struct Storage<T>: DynamicProperty where T: Codable {
    private let key: String
    private let store: UserDefaults
    
    @State private var internalValue: T {
        willSet { updateStore(with: newValue) }
    }
    
    public var wrappedValue: T {
        get { internalValue }
        nonmutating set { internalValue = newValue }
    }
    
    public var projectedValue: Binding<T> {
        Binding { internalValue } set: { internalValue = $0 }
    }
    
    public init(wrappedValue: T, _ key: String, store: UserDefaults = .shared) {
        self.key = key
        self.store = store
        self._internalValue = .init(initialValue: wrappedValue)
    }
    
    public func update() {
        if let newValue = fetchValueFromStore() {
            Task {
                await MainActor.run { internalValue = newValue }
            }
        }
    }
    
    private func updateStore(with newValue: T) {
        switch newValue {
        case is Bool, is Int, is Float, is Double, is String, is [String], is Data:
            store.set(newValue, forKey: key)
        default:
            if let data = try? JSONEncoder().encode(newValue) {
                store.set(data, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }
    }
    
    private func fetchValueFromStore() -> T? {
        switch T.self {
        case is Bool.Type:
            store.bool(forKey: key) as? T
        case is Int.Type:
            store.integer(forKey: key) as? T
        case is Float.Type:
            store.float(forKey: key) as? T
        case is Double.Type:
            store.double(forKey: key) as? T
        case is String.Type:
            store.string(forKey: key) as? T
        case is [String].Type:
            store.stringArray(forKey: key) as? T
        case is Data.Type:
            store.data(forKey: key) as? T
        default:
            if let data = store.data(forKey: key),
               let decoded = try? JSONDecoder().decode(T.self, from: data) {
                decoded
            } else {
                nil
            }
        }
    }
}

public extension Storage {
    init(wrappedValue: T, _ key: UserDefaultsKey, store: UserDefaults = .shared) {
        self.key = key.rawValue
        self.store = store
        self._internalValue = .init(initialValue: wrappedValue)
    }
}
