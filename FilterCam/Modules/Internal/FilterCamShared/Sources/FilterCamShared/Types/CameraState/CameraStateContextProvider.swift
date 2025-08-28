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
            logger.debug("""
New camera state:
Capture mode: \(String(describing: state.captureMode))
Camera Position: \(String(describing: state.cameraPosition))
Quality Prioritization: \(String(describing: state.qualityPrioritization))
Flash Mode: \(String(describing: state.flashMode))
Aspect Ratio: \(String(describing: state.aspectRatio))
""")
        }
        
        var currentState: CameraState? {
            logger.debug("Called camera state getter")
            return nil
        }
    }
    
    struct NoopContextProvider: ContextProvider {
        func update(with state: CameraState) async throws {}
        var currentState: CameraState? { nil }
    }
}

private extension CameraState {
    struct ChainContextProvider<Provider1, Provider2>: ContextProvider where Provider1: ContextProvider, Provider2: ContextProvider {
        private let provider1: Provider1
        private let provider2: Provider2
        
        init(provider1: Provider1, provider2: Provider2) {
            self.provider1 = provider1
            self.provider2 = provider2
        }
        
        var currentState: CameraState? {
            get async throws {
                _ = try await provider2.currentState
                return try await provider1.currentState
            }
        }
        
        func update(with state: CameraState) async throws {
            try await provider1.update(with: state)
            try await provider2.update(with: state)
        }
    }
}

extension CameraState.ContextProvider {
    func chain(to otherProvider: some CameraState.ContextProvider) -> some CameraState.ContextProvider {
        return CameraState.ChainContextProvider(provider1: self, provider2: otherProvider)
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
    static func intent<I>(_ intent: I.Type) async -> CameraState where I: CameraCaptureIntent, I.AppContext == CameraState {
        let provider = IntentContextProvider(intent: intent).chain(to: .logging)
        if let currentState = try? await provider.currentState {
            return currentState
        } else {
            return .init(contextProvider: provider)
        }
    }
}
