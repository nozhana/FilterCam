//
//  FilterCamApp.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import SwiftUI
import LockedCameraCapture

@main
struct FilterCamApp: App {
    @Environment(\.mediaStore) private var mediaStore
    @Environment(\.scenePhase) private var scenePhase
    
    @ObservedObject private var toaster  = Toaster.shared
    @StateObject private var thermalStateObserver = ThermalStateObserver()
    
    var body: some Scene {
        WindowGroup {
            CameraViewFinder()
                .environment(\.thermalState, thermalStateObserver.thermalState)
                .environmentObject(thermalStateObserver)
                .toasterContainer(toaster)
                .databaseContainer()
                .task(id: scenePhase, priority: .utility) {
                    guard scenePhase == .active else { return }
                    if #available(iOS 18.0, *) {
                        try? await Task.sleep(for: .seconds(0.5))
                        importLockedCameraContent()
                    }
                }
        }
    }
    
    @available(iOS 18.0, *)
    private func importLockedCameraContent() {
        let urls = LockedCameraCaptureManager.shared.sessionContentURLs
        for url in urls {
            let contents = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
            for contentURL in contents {
                guard let data = try? Data(contentsOf: contentURL),
                      let photo = try? JSONDecoder().decode(Photo.self, from: data) else { continue }
                _ = try? mediaStore.savePhoto(photo)
            }
            Task {
                try await LockedCameraCaptureManager.shared.invalidateSessionContent(at: url)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            mediaStore.refreshThumbnail()
        }
    }
}
