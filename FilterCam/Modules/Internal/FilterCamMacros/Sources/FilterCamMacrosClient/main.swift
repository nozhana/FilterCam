import SwiftUI

import FilterCamMacros

// MARK: - OptionSetBuilder
@OptionSetBuilder<UInt8>
struct FlightDestinations {
    private enum Options: Int, CaseIterable {
        case berlin, hamburg, vienna, zurich, paris
    }
    
    static let germanyTour: FlightDestinations = [.berlin, .hamburg]
}

extension FlightDestinations {
    var members: [FlightDestinations] {
        [FlightDestinations.berlin, .hamburg, .vienna, .zurich, .paris]
            .filter(contains)
    }
}

var destinations: FlightDestinations = .germanyTour
print(destinations.members)
destinations.insert(.vienna)
print(destinations.members)
