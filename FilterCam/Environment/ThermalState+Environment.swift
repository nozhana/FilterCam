//
//  ThermalState+Environment.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/26/25.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var thermalState = ProcessInfo.ThermalState.nominal
}
