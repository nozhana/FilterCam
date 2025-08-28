//
//  UserDefaults+.swift
//  FilterCamBase
//
//  Created by Nozhan A. on 8/28/25.
//

import Foundation

public extension UserDefaults {
#if DEBUG
    static let preview = {
        let storage = UserDefaults(suiteName: #file)!
        storage.removePersistentDomain(forName: #file)
        return storage
    }()
#endif
    
    static let shared = {
#if DEBUG
        return ProcessInfo.isRunningPreviews ? preview : standard
#else
        return standard
#endif
    }()
}

public extension UserDefaults {
    static var cameraSwitchRotationEffect: Bool {
        shared.bool(forKey: UserDefaultsKey.cameraSwitchRotationEffect.rawValue)
    }
    
    static var showDeveloperSettings: Bool {
        shared.bool(forKey: UserDefaultsKey.showDeveloperSettings.rawValue)
    }
    
    static var useMetalRendering: Bool {
        shared.bool(forKey: UserDefaultsKey.useMetalRendering.rawValue)
    }
    
    static var useFilters: Bool {
        shared.bool(forKey: UserDefaultsKey.useFilters.rawValue)
    }
    
    static var mockCamera: Bool {
        shared.bool(forKey: UserDefaultsKey.mockCamera.rawValue)
    }
}
