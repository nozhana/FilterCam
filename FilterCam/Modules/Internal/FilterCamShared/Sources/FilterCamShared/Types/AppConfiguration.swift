//
//  AppConfiguration.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/29/25.
//

import Foundation

public struct AppConfiguration: Sendable {
    public let captureDirectory: URL
    
    public init(captureDirectory: URL) {
        self.captureDirectory = captureDirectory
    }
    
    public static let shared = {
        var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        url.append(component: "capture")
        if !FileManager.default.fileExists(atPath: url.path()) {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        let config = AppConfiguration(captureDirectory: url)
        return config
    }()
    
#if DEBUG
    public static let preview = {
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        url.append(component: "capture")
        try? FileManager.default.removeItem(at: url)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        let config = AppConfiguration(captureDirectory: url)
        return config
    }()
#endif
}
