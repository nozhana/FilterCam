//
//  DatabaseService+Environment.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/25/25.
//

import FilterCamInterfaces
import FilterCamUtilities
import SwiftUI

extension EnvironmentValues {
#if DEBUG
    @Entry var database: DatabaseService = ProcessInfo.isRunningPreviews ? .inMemory : .default
#else
    @Entry var database: DatabaseService = .default
#endif
}

extension View {
    func databaseContainer(_ database: some DatabaseService = .default) -> some View {
        self
            .modelContainer(database.container)
            .environment(\.database, database)
    }
}
