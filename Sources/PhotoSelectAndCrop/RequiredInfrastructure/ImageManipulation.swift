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

    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()

    let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y, width: image.size.width, height: image.size.height)

    context?.clip(to: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))

    image.draw(in: drawRect)

    let subImage = UIGraphicsGetImageFromCurrentImageContext()

    UIGraphicsEndImageContext()
    return subImage!
}
