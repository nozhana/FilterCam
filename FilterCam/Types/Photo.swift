//
//  Photo.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/19/25.
//

import Foundation

struct Photo {
    let data: Data
    let timestamp = Date.now
    let isProxy: Bool
    
    init(data: Data, isProxy: Bool = false) {
        self.data = data
        self.isProxy = isProxy
    }
}
