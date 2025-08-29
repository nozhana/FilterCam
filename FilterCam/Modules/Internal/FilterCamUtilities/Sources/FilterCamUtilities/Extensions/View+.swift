//
//  View+.swift
//  FilterCamUtilities
//
//  Created by Nozhan A. on 8/21/25.
//

#if canImport(SwiftUI)
import SwiftUI

public extension View {
    @ViewBuilder
    func `if`(_ predicate: Bool, @ViewBuilder content: @escaping (Self) -> some View) -> some View {
        if predicate {
            content(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`(_ predicate: Bool, @ViewBuilder content: @escaping (Self) -> some View, @ViewBuilder else otherContent: @escaping (Self) -> some View) -> some View {
        if predicate {
            content(self)
        } else {
            otherContent(self)
        }
    }
    
    @ViewBuilder
    func ifLet<T>(_ optional: T?, @ViewBuilder content: @escaping (Self, T) -> some View) -> some View {
        if let wrapped = optional {
            content(self, wrapped)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func ifLet<T>(_ optional: T?, @ViewBuilder content: @escaping (Self, T) -> some View, @ViewBuilder else otherContent: @escaping (Self) -> some View) -> some View {
        if let wrapped = optional {
            content(self, wrapped)
        } else {
            otherContent(self)
        }
    }
}

#endif
