//
//  PreviewSource.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

public protocol PreviewSource: Sendable {
    func connect(to target: PreviewTarget)
}
