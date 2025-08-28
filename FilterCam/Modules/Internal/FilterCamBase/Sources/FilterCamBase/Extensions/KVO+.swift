//
//  KVO+.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import Foundation

public extension NSKeyValueObservation {
    func store(in collection: inout some RangeReplaceableCollection<NSKeyValueObservation>) {
        collection.append(self)
    }
    
    func store(in set: inout Set<NSKeyValueObservation>) {
        set.insert(self)
    }
}
