//
//  BinaryFloatingPoint+.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/26/25.
//

import Foundation

extension BinaryFloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
    
    func stepped(by quotient: Self) -> Self {
        (self / quotient).rounded() * quotient
    }
}
