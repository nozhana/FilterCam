//
//  SettingsView.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(UserDefaultsKey.cameraSwitchRotationEffect.rawValue, store: .shared)
    private var rotateCamera = true
    
    @AppStorage(UserDefaultsKey.showDeveloperSettings.rawValue, store: .shared)
    private var showDeveloperSettings = false
    
    @AppStorage(UserDefaultsKey.useMetalRendering.rawValue, store: .shared)
    private var useMetalRendering = false
    
    @EnvironmentObject private var cameraModel: CameraModel
    
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
                        Toggle("Use Metal Rendering", systemImage: "cpu.fill", isOn: $useMetalRendering)
                            .onChange(of: useMetalRendering) { _, newValue in
                                Task {
                                    await cameraModel.switchCaptureService(newValue ? try .metal() : try .default())
                                }
                            }
                    } header: {
                        Label("Developer Settings", systemImage: "hammer.fill")
                    }
                    
                    Section {
                        Button("Hide Developer Settings", systemImage: "eye.slash.fill") {
                            showDeveloperSettings = false
                        }
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
}

#Preview {
    SettingsView()
}
