//
//  URL+.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/24/25.
//

import UIKit

extension URL {
    static let appSettingsOrGeneralSettings = {
        let urlString = UIApplication.openSettingsURLString
        let settingsURL = URL(string: urlString)!
        let appSettingsURL = URL(string: Bundle.main.bundleIdentifier!, relativeTo: settingsURL)
        return appSettingsURL ?? settingsURL
    }()
}
