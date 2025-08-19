//
//  CameraStateContextProvider.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation
import AppIntents

extension CameraState {
    protocol ContextProvider {
        var currentState: CameraState? { get async throws }
        func update(with state: CameraState) async throws
    }
    
    @available(iOS 18.0, *)
    struct IntentContextProvider<Intent>: ContextProvider where Intent: CameraCaptureIntent, Intent.AppContext == CameraState {
        private let intent: Intent.Type
        
        init(intent: Intent.Type) {
            self.intent = intent
        }
        
        var currentState: CameraState? {
            get async throws {
                try await intent.appContext
            }
        }
        
        func update(with state: CameraState) async throws {
            try await intent.updateAppContext(state)
        }
    }
    
    struct LoggingContextProvider: ContextProvider {
        func update(with state: CameraState) async throws {
            let data = try JSONEncoder().encode(state)
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            let prettyJson = String(data: prettyData, encoding: .utf8)!
            logger.debug("New camera state:\n\(prettyJson)")
        }
        
        var currentState: CameraState? { nil }
    }
    
    struct NoopContextProvider: ContextProvider {
        func update(with state: CameraState) async throws {}
        var currentState: CameraState? { nil }
    }
}

@available(iOS 18.0, *)
extension CameraState.ContextProvider where Self == CameraState.NoopContextProvider {
    static func intent<I>(_ intent: I.Type) -> CameraState.IntentContextProvider<I> where I: CameraCaptureIntent, I.AppContext == CameraState {
        .init(intent: intent)
    }
}

extension CameraState.ContextProvider where Self == CameraState.LoggingContextProvider {
    static var logging: CameraState.LoggingContextProvider { .init() }
}

extension CameraState.ContextProvider where Self == CameraState.NoopContextProvider {
    static var noop: CameraState.NoopContextProvider { .init() }
}

extension CameraState {
    static let idle = CameraState(contextProvider: .noop)
    static let logging = CameraState(contextProvider: .logging)
    @available(iOS 18.0, *)
    static func intent<I>(_ intent: I.Type) -> CameraState where I: CameraCaptureIntent, I.AppContext == CameraState {
        .init(contextProvider: .intent(intent))
    }
}
