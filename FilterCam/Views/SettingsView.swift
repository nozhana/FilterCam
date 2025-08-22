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
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Camera Switch Rotation", systemImage: "camera.rotate", isOn: $rotateCamera)
                } header: {
                    Label("Effects", systemImage: "sparkles")
                        .font(.caption)
                }
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
