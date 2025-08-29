//
//  Toaster.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import SwiftUI

public final class Toaster: ObservableObject {
    @Published public private(set) var toasts = [Toast]()
    
    private init() {}
    
    public static let shared = Toaster()
    
    public func showToast(_ message: Text, icon: Image? = nil, tint: Color? = nil, duration: TimeInterval = 2.0) {
        showToast(.init(message: message, icon: icon, tint: tint, duration: duration))
    }
    
    public func showToast(_ message: LocalizedStringKey, icon: Image? = nil, tint: Color? = nil, duration: TimeInterval = 2.0) {
        showToast(.init(message: Text(message), icon: icon, tint: tint, duration: duration))
    }
    
    public func showToast(verbatim message: String, icon: Image? = nil, tint: Color? = nil, duration: TimeInterval = 2.0) {
        showToast(.init(message: Text(message), icon: icon, tint: tint, duration: duration))
    }
    
    public func showToast(_ toast: Toast) {
        Task {
            await MainActor.run {
                withAnimation(.bouncy) {
                    toasts.append(toast)
                }
            }
            try? await Task.sleep(for: .seconds(toast.duration))
            await MainActor.run {
                withAnimation(.smooth) {
                    toasts.removeAll(where: { $0 == toast })
                }
            }
        }
    }
    
    public func removeToast(_ toast: Toast) {
        Task {
            await MainActor.run {
                withAnimation(.snappy) {
                    toasts.removeAll { $0 == toast }
                }
            }
        }
    }
}

public struct Toast: Equatable {
    public var message: Text
    public var icon: Image?
    public var tint: Color?
    public var duration: TimeInterval = 2.0
}

public extension Toast {
    static func `default`(_ message: Text, duration: TimeInterval = 2.0) -> Toast {
        .init(message: message, duration: duration)
    }
    
    static func info(_ message: Text, duration: TimeInterval = 2.0) -> Toast {
        .init(message: message, icon: .init(systemName: "info.circle.fill"), tint: .blue, duration: duration)
    }
    
    static func error(_ message: Text, duration: TimeInterval = 2.0) -> Toast {
        .init(message: message, icon: .init(systemName: "exclamationmark.circle.fill"), tint: .red, duration: duration)
    }
    
    static func warning(_ message: Text, duration: TimeInterval = 2.0) -> Toast {
        .init(message: message, icon: .init(systemName: "exclamationmark.triangle.fill"), tint: .yellow, duration: duration)
    }
}
