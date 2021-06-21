//
//  ImageAttributes.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 26/02/21.
//

import SwiftUI

public class ImageAttributes: ObservableObject {
    
    @Published var image: UIImage? // cropped and / or scaled image take from originalImage
    @Published var originalImage: UIImage? // the original image selected before cropping or scaling
    @Published var scale: CGFloat // the magnificaiton of the cropped image
    @Published var xWidth: CGFloat // used to detrermine the position of the original image in the "viewfinder"
    @Published var yHeight: CGFloat // same as above
    public var position: CGSize { // computed from the previous two variables.
        get {
            return CGSize(width: xWidth, height: yHeight)
        }
    }
    
    //
    var swiftUIImage: Image?
    
    public init(image: UIImage?, originalImage: UIImage?, scale: CGFloat, xWidth: CGFloat, yHeight: CGFloat) {
        self.image = image
        self.originalImage = originalImage
        self.scale = scale
        self.xWidth = xWidth
        self.yHeight = yHeight
    }
    
    public init(withSFSymbol name: String) {
        self.swiftUIImage = Image(systemName: name)
        self.scale = 1.0
        self.xWidth = 1.0
        self.yHeight = 1.0
    }
    
    public init(withImage name: String) {
        self.swiftUIImage = Image(name)
        /// Setting self.scale to 15 will keep an image from the Asset catalog from being too small. See line 159 in ImageMoveAndScaleSheet.swift.
        self.scale = 15.0
        self.xWidth = 1.0
        self.yHeight = 1.0
        
    }
}

