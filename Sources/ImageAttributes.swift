//
//  ImageAttributes.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 26/02/21.
//

import SwiftUI

///A collection of attributes used to position an image in the ImageMoveAndScaleSheet at a determined scale and offset as well as a cropped image representing the same.
///Setting self.scale to 15 will keep an image from the Asset catalog from being too small. See line 159 in ImageMoveAndScaleSheet.swift.

public class ImageAttributes: ObservableObject {
    
    ///Cropped and / or scaled image take from originalImage
    @Published public var image: Image
    
    ///The original image selected before cropping or scaling
    @Published public var originalImage: UIImage?
    
    ///The cropped image as a UIImage for easier persistence in applcations.
    @Published public var croppedImage: UIImage?
    
    ///The magnification of the cropped image
    @Published public var scale: CGFloat
    
    ///Used to determine the horizontal position or x-offset of the original image in the "viewfinder"
    @Published public var xWidth: CGFloat
    
    ///Used to determine the vertical position or y-offset of the original image in the "viewfinder"
    @Published public var yHeight: CGFloat
    
    ///A CGSize computed from xWidth and yHeight.
    public var position: CGSize {
        get {
            return CGSize(width: xWidth, height: yHeight)
        }
    }

    ///Used to create an ImageAssets object from properties which are for example stored in CoreData or @AppStorage.
    init(image: Image, originalImage: UIImage?, croppedImage: UIImage?, scale: CGFloat, xWidth: CGFloat, yHeight: CGFloat) {
        self.image = image
        self.originalImage = originalImage
        self.croppedImage = croppedImage
        self.scale = scale
        self.xWidth = xWidth
        self.yHeight = yHeight
    }
    
    ///Allows ImageAttributes to be configured with an SF Symbol name string.
    ///For example: `ImageAttributes("person.crop.circle")`
    public init(withSFSymbol name: String) {
        self.image = Image(systemName: name)
        self.scale = 1.0
        self.xWidth = 1.0
        self.yHeight = 1.0
    }
    
    ///Allows ImageAttributes to be configured with an image from the Asset Catalogue.
    public init(withImage name: String) {
        self.image = Image(name)
        self.scale = 15.0
        self.xWidth = 1.0
        self.yHeight = 1.0
        
    }
}

