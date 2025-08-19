//
//  PhotoCaptureError.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

enum PhotoCaptureError: LocalizedError, CustomStringConvertible {
    case noPhotoData
    
    var description: String {
        switch self {
        case .noPhotoData: "No Photo Data"
        }
    }
    
    var errorDescription: String? {
        description
    }
}
