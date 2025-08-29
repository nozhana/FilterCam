//
//  OutputMedium.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import Foundation

public protocol OutputMedium: Identifiable, Codable {
    var id: UUID { get }
    var data: Data { get }
    var timestamp: Date { get }
}
