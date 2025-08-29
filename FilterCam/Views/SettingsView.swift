//
//  SettingsView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import FilterCamBase
import FilterCamMacros
import FilterCamShared
import SwiftUI

@Provider(\.mediaStore)
@Provider(\.cameraModel, observed: true)
struct SettingsView: View {
    @Storage(.cameraSwitchRotationEffect) private var rotateCamera = true
    @Storage(.showDeveloperSettings) private var showDeveloperSettings = false
    @Storage(.useMetalRendering) private var useMetalRendering = false
    @Storage(.useFilters) private var useFilters = false
    @Storage(.mockCamera) private var mockCamera = false
    
    @State private var stepsToBecomeADeveloper = 10
    @State private var stepsResetTask: Task<Void, Error>?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Camera Switch Rotation", systemImage: "camera.rotate", isOn: $rotateCamera)
                } header: {
                    Label("Effects", systemImage: "sparkles")
                        .font(.caption)
                }
                
                Section {
                    Button {
                        UIPasteboard.general.string = UIDevice.current.identifierForVendor?.uuidString
                        guard !showDeveloperSettings, stepsToBecomeADeveloper > 0 else { return }
                        withAnimation(.snappy) {
                            stepsToBecomeADeveloper -= 1
                            if stepsToBecomeADeveloper == 0 {
                                showDeveloperSettings = true
                            }
                        }
                        stepsResetTask?.cancel()
                        stepsResetTask = Task {
                            try await Task.sleep(for: .seconds(3))
                            try Task.checkCancellation()
                            await MainActor.run {
                                withAnimation(.smooth) {
                                    stepsToBecomeADeveloper = 10
                                }
                            }
                        }
                    } label: {
                        LabeledContent("Device ID", value: UIDevice.current.identifierForVendor?.uuidString ?? "Unknown")
                    }
                } header: {
                    Label("Info", systemImage: "info.circle.fill")
                }
                
                if showDeveloperSettings {
                    Section {
                        Button("Wipe Gallery", systemImage: "trash.fill", role: .destructive) {
                            try? mediaStore.wipeGallery()
                        }
                        .foregroundStyle(.red)
                        Toggle("Mock Camera", systemImage: "camera.macro", isOn: $mockCamera)
                            .onChange(of: mockCamera) {
                                refreshCaptureService()
                            }
                        Toggle("Use Metal Rendering", systemImage: "cpu.fill", isOn: $useMetalRendering.animation())
                        if useMetalRendering {
                            Toggle("Use Filters", systemImage: "camera.filters", isOn: $useFilters)
                        }
                        Button("Hide Developer Settings", systemImage: "eye.slash.fill") {
                            showDeveloperSettings = false
                        }
                    } header: {
                        Label("Developer Settings", systemImage: "hammer.fill")
                    }
                    .onChange(of: useMetalRendering != useFilters) {
                        refreshCaptureService()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                Group {
                    if stepsToBecomeADeveloper == 0 || showDeveloperSettings {
                        Text("You're now a developer! 🎉")
                    } else {
                        Text("You're ^[\(stepsToBecomeADeveloper) step](inflect: true) away from becoming a developer!")
                            .contentTransition(.numericText(value: Double(stepsToBecomeADeveloper)))
                    }
                }
                .font(.caption.bold().smallCaps())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.background.secondary.opacity(0.5), in: .capsule(style: .continuous))
                .opacity(CGFloat(10 - stepsToBecomeADeveloper) / 10.0)
                .padding(.bottom, 32)
            }
            .safeAreaInset(edge: .bottom, spacing: 16) {
                VStack {
                    Text("Made with 💜")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("@nozhana", destination: URL(string: "https://github.com/nozhana")!)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Settings")
        }
    }
    
    private func refreshCaptureService() {
        Task {
            let (service, renderMode): (CaptureService, RenderMode) = switch (useMetalRendering, useFilters) {
            case (false, _):
                (.default(), .default)
            case (true, false):
                (try .metal(), .metal)
            case (true, true):
                (try .metalWithFilters(), .metalWithFilters)
            }
            cameraModel.renderMode = renderMode
            await cameraModel.switchCaptureService(service)
        }
    }
}

#Preview {
    SettingsView()
}
