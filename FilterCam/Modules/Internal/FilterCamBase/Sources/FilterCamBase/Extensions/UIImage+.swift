//
//  UIImage+.swift
//  FilterCam
//
//  Created by Nozhan A. on 8/22/25.
//

#if canImport(UIKit)
import UIKit

public extension UIImage {
    func cropped(to rect: CGRect) -> UIImage? {
        guard let croppedRef: CGImage = self.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: croppedRef, scale: 1, orientation: imageOrientation)
    }
    
    func cropped(to ratio: CGFloat) -> UIImage? {
        let minScale = min(size.width / ratio, size.height)
        let width = ratio * minScale
        let height = minScale
        let originX = (size.width - width) / 2
        let originY = (size.height - height) / 2
        let croppingRect = CGRect(x: originX, y: originY, width: width, height: height)
        return cropped(to: croppingRect)
    }
}

#endif
