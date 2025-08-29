//
//  File.swift
//  FilterCamResources
//
//  Created by Nozhan A. on 8/29/25.
//

#if canImport(SwiftUI)
import SwiftUI

@dynamicMemberLookup
public enum Resource {
    public static subscript(dynamicMember keyPath: KeyPath<AssetNames, String>) -> Image {
        self[image: keyPath]
    }
    
    public static subscript(dynamicMember keyPath: KeyPath<AssetNames, String>) -> UIImage {
        self[uiImage: keyPath]
    }
    
    public static subscript(dynamicMember keyPath: KeyPath<AssetNames, String>) -> Data {
        self[data: keyPath]
    }
    
    public static subscript(image keyPath: KeyPath<AssetNames, String>) -> Image {
        Image(AssetNames.shared[keyPath: keyPath], bundle: .module)
    }
    
    public static subscript(uiImage keyPath: KeyPath<AssetNames, String>) -> UIImage {
        UIImage(named: AssetNames.shared[keyPath: keyPath], in: .module, compatibleWith: nil)!
    }
    
    public static subscript(data keyPath: KeyPath<AssetNames, String>) -> Data {
        self[uiImage: keyPath].pngData()!
    }
}

public typealias R = Resource

public struct AssetNames {
    private init() {}
    fileprivate static let shared = AssetNames()
    
    public let camPreview = "cam-preview"
    public let donut = "donut"
}

#endif
