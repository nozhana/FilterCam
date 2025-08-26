//
//  ThermalStateObserver.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/26/25.
//

import Foundation

final class ThermalStateObserver: KVOAsyncObserver<ProcessInfo, ProcessInfo.ThermalState>, ObservableObject {
    @Published private(set) var thermalState: ProcessInfo.ThermalState = .nominal

    convenience init() {
        self.init(.processInfo, child: "thermalState")
        observeState()
    }
    
    private func observeState() {
        Task {
            for await thermalState in changes {
                guard let thermalState else { continue }
                await MainActor.run {
                    self.thermalState = thermalState
                }
            }
        }
    }
}
