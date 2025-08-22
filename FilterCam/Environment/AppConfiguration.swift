//
//  AppConfiguration.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import SwiftUI

struct AppConfiguration: Sendable {
    let captureDirectory: URL
    
    var moviesDirectory: URL {
        let directory = captureDirectory.appending(component: "movies", directoryHint: .isDirectory)
        if !FileManager.default.fileExists(atPath: directory.path()) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
    
    static let shared = {
        var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url.append(component: "capture")
        if !FileManager.default.fileExists(atPath: url.path()) {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        let config = AppConfiguration(captureDirectory: url)
        return config
    }()
    
#if DEBUG
    static let preview = {
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        url.append(component: "capture")
        try? FileManager.default.removeItem(at: url)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        PreviewAssets.initialPhotos
            .compactMap {
                if let data = try? JSONEncoder().encode($0) {
                    return ($0, data)
                }
                return nil
            }
            .forEach { try? $0.1.write(to: url.appendingPathComponent($0.0.id.uuidString, conformingTo: .json)) }
        
        let config = AppConfiguration(captureDirectory: url)
        return config
    }()
#endif
}

extension EnvironmentValues {
#if DEBUG
    @Entry var appConfiguration = ProcessInfo.isRunningPreviews ? AppConfiguration.preview : .shared
#else
    @Entry var appConfiguration = AppConfiguration.shared
#endif
}
