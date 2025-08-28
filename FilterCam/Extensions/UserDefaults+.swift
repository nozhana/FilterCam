//
//  UserDefaults+.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/28/25.
//

import Foundation

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
