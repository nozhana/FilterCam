//
//  CameraFilter.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

import GPUImage
import SwiftUI

enum CameraFilter: Hashable, Codable, RawRepresentable, Comparable, FilterGenerator {
    case none
    case noir
    case blur(radius: Float = 20.0)
    case sepia(intensity: Float = 0.9)
    case haze(distance: Float = 0.2, slope: Float = 0.0)
    case sharpen(sharpness: Float = 0.5)
    case lookup(image: LookupImage, intensity: Float = 1.0)
    case custom(CustomFilter)
    
    var isCustom: Bool {
        if case .custom = self {
            return true
        }
        return false
    }
    
    var rawValue: String {
        switch self {
        case .none:
            "none"
        case .noir:
            "noir"
        case .blur:
            "blur"
        case .sepia:
            "sepia"
        case .haze:
            "haze"
        case .sharpen:
            "sharpen"
        case .lookup(let image, _):
            "lookup-\(image.rawValue)"
        case .custom(let customFilter):
            "custom-\(customFilter.title)"
        }
    }
    
    var title: String {
        switch self {
        case .none:
            "Original"
        case .noir:
            "Noir"
        case .blur:
            "Blur"
        case .sepia:
            "Sepia"
        case .haze:
            "Haze"
        case .sharpen:
            "Sharpen"
        case .lookup(let image, _):
            image.title
        case .custom(let customFilter):
            customFilter.title
        }
    }
    
    private var index: Int {
        switch self {
        case .none: 0
        case .noir: 1
        case .blur: 2
        case .sepia: 3
        case .haze: 4
        case .sharpen: 5
        case .lookup(let image, _): 6 + image.rawValue
        case .custom(let customFilter): -1 - customFilter.layoutIndex
        }
    }
    
    static func < (lhs: CameraFilter, rhs: CameraFilter) -> Bool {
        lhs.index < rhs.index
    }
    
    init?(rawValue: String) {
        if let value: CameraFilter = switch rawValue {
        case "none": CameraFilter.none
        case "noir": .noir
        case "blur": .blur()
        case "sepia": .sepia()
        case "haze": .haze()
        case "sharpen": .sharpen()
        default:
            if let match = rawValue.firstMatch(of: /lookup-([0-9]+)/)?.output.1,
               let number = Int(match),
               let lookupImage = LookupImage(rawValue: number) {
                .lookup(image: lookupImage)
            } else {
                nil
            }
        } {
            self = value
        } else {
            return nil
        }
    }
    
    func makeOperation() -> any ImageProcessingOperation {
        switch self {
        case .none: return ImageRelay()
        case .custom(let customFilter): return customFilter.makeOperation()
        case .noir: return Luminance()
        case .blur(let radius):
            let blur = GaussianBlur()
            blur.blurRadiusInPixels = radius
            return blur
        case .sepia(let intensity):
            let sepia = SepiaToneFilter()
            sepia.intensity = intensity
            return sepia
        case .haze(let distance, let slope):
            let haze = Haze()
            haze.distance = distance
            haze.slope = slope
            return haze
        case .sharpen(let sharpness):
            let sharpen = Sharpen()
            sharpen.sharpness = sharpness
            return sharpen
        case .lookup(let lookupImage, let intensity):
            let lookup = LookupFilter()
            lookup.lookupImage = .init(image: UIImage(resource: lookupImage.resource))
            lookup.intensity = intensity
            return lookup
        }
    }
}

extension CameraFilter {
    enum LookupImage: Int, Codable, CaseIterable, Identifiable {
        case portrait35mm
        case agfaVista
        case classicChrome
        case eliteChrome
        case kodachrome
        case moodyFilm
        case polaroidColor
        case portra800
        case velvia100
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .portrait35mm:
                "Portrait 35mm"
            case .agfaVista:
                "Agfa Vista"
            case .classicChrome:
                "Classic Chrome"
            case .eliteChrome:
                "Elite Chrome"
            case .kodachrome:
                "KodaChrome"
            case .moodyFilm:
                "Moody Film"
            case .polaroidColor:
                "Polaroid Colors"
            case .portra800:
                "Portra 800"
            case .velvia100:
                "Velvia 100"
            }
        }
        
        var resource: ImageResource {
            switch self {
            case .portrait35mm: .lut35MmPortrait
            case .agfaVista: .lutAgfaVista
            case .classicChrome: .lutClassicChrome
            case .eliteChrome: .lutEliteChrome
            case .kodachrome: .lutKodachrome
            case .moodyFilm: .lutMoodyFilm
            case .polaroidColor: .lutPolaroidColors
            case .portra800: .lutPortra800
            case .velvia100: .lutVelvia100
            }
        }
    }
}

extension CameraFilter {
    mutating func update(with floatValue: Float, atIndex index: Int = 0) {
        switch self {
        case .none: break
        case .noir: break
        case .blur: self = .blur(radius: floatValue)
        case .sepia: self = .sepia(intensity: floatValue)
        case .haze(let distance, let slope):
            self = .haze(distance: index == 0 ? floatValue : distance,
                         slope: index == 1 ? floatValue : slope)
        case .sharpen:
            self = .sharpen(sharpness: floatValue)
        case .lookup(let image, _):
            self = .lookup(image: image, intensity: floatValue)
        case .custom: break
        }
    }
    
    mutating func update(with booleanValue: Bool, atIndex index: Int = 0) {}
}
