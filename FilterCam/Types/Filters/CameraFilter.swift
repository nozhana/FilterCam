//
//  CameraFilter.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/23/25.
//

import GPUImage
import UIKit

enum CameraFilter: Hashable, Codable, RawRepresentable, Comparable {
    case none
    case noir
    case sepia(intensity: Float = 0.9)
    case haze(distance: Float = 0.2, slope: Float = 0.0)
    case sharpen(sharpness: Float = 0.5)
    case lookup(image: LookupImage, intensity: Float = 0.8)
    
    var rawValue: String {
        switch self {
        case .none:
            "none"
        case .noir:
            "noir"
        case .sepia:
            "sepia"
        case .haze:
            "haze"
        case .sharpen:
            "sharpen"
        case .lookup(let image, _):
            "lookup-\(image.rawValue)"
        }
    }
    
    var title: String {
        switch self {
        case .none:
            "Original"
        case .noir:
            "Noir"
        case .sepia:
            "Sepia"
        case .haze:
            "Haze"
        case .sharpen:
            "Sharpen"
        case .lookup(let image, _):
            image.title
        }
    }
    
    private var index: Int {
        switch self {
        case .none: 0
        case .noir: 1
        case .sepia: 2
        case .haze: 3
        case .sharpen: 4
        case .lookup(let image, _): 5 + image.rawValue
        }
    }
    
    static func < (lhs: CameraFilter, rhs: CameraFilter) -> Bool {
        lhs.index < rhs.index
    }
    
    init?(rawValue: String) {
        if let value: CameraFilter = switch rawValue {
        case "none": CameraFilter.none
        case "noir": .noir
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
        case .noir: return Luminance()
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
    enum LookupImage: Int, Codable {
        case portrait35mm
        case agfaVista
        case classicChrome
        case eliteChrome
        case kodachrome
        case moodyFilm
        case polaroidColor
        case portra800
        case velvia100
        
        var title: String {
            switch self {
            case .portrait35mm:
                "Portrait 35mm"
            case .agfaVista:
                "Agfa Vist"
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
