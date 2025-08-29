//
//  MovieOutputService.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

import FilterCamInterfaces
import FilterCamShared
import Foundation

protocol MovieOutputService: OutputService {
    func recordVideo(with features: VideoFeatures) async throws -> Video
    func stopRecording()
}
