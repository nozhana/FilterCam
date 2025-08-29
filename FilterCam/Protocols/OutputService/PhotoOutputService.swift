//
//  PhotoOutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import FilterCamShared
import Foundation

protocol PhotoOutputService: OutputService {
    func capturePhoto(with features: PhotoFeatures) async throws -> Photo
}
