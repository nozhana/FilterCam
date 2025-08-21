//
//  FilterCamWidgetsBundle.swift
//  FilterCamWidgets
//
//  Created by Nozhan A. on 8/20/25.
//

import WidgetKit
import SwiftUI

@main
struct FilterCamWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 18.0, *) {
            FilterCamLockScreenControl()
        }
    }
}
