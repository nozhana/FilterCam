//
//  UserDefaultsKey.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import Foundation

enum UserDefaultsKey: String {
    case cameraSwitchRotationEffect = "cam_switch_rotation"
    case showDeveloperSettings = "show_dev_settings"
    case useMetalRendering = "use_metal"
}

extension UserDefaults {
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
