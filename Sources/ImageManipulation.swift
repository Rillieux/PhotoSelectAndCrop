//
//  ImageManipulation.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 03/01/21.
//

import UIKit

/// Crops a UIImage
/// - Parameters:
///   - image: the original image before processing.
///   - rect: the CGRect to which the image will be cropped.
/// - Returns: UIImage.
func croppedImage(from image: UIImage, croppedTo rect: CGRect) -> UIImage {

    ///The crop rect is computed in the original image's pixel space, so the
    ///renderer must use scale 1 and sRGB to match the dimensions and color
    ///behavior of the legacy UIGraphicsBeginImageContext this replaced.
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.preferredRange = .standard

    let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)

    return renderer.image { context in
        context.cgContext.clip(to: CGRect(origin: .zero, size: rect.size))

        let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y, width: image.size.width, height: image.size.height)
        image.draw(in: drawRect)
    }
}
