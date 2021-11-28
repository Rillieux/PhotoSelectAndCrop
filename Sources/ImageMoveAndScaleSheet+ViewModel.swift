//
//  ImageMoveAndScaleSheet+ViewModel.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 22/11/21.
//

import SwiftUI

extension ImageMoveAndScaleSheet {
    
    class ViewModel: ObservableObject {
        
        @Published var image = Image(systemName: "star.fill")
        @Published var originalImage: UIImage?
        @Published var scale: CGFloat = 1.0
        @Published var xWidth: CGFloat = 0.0
        @Published var yHeight: CGFloat = 0.0
        var position: CGSize {
            get {
                return CGSize(width: xWidth, height: yHeight)
            }
        }
        //Localized strings
        let moveAndScale = NSLocalizedString("Move and Scale", comment: "indicate that the user may use gestures to move and or scale the image")
        let selectPhoto = NSLocalizedString("Select a photo by tapping the icon below", comment: "indicate that the user may select a photo by tapping on the green icon")
        let cancelSheet = NSLocalizedString("Cancel", comment: "indicate that the user cancel the action, closing the sheet")
        let usePhoto = NSLocalizedString("Use photo", comment: "indicate that the user may use the photo as currently displayed")

        func updateImageAttributes(_ imageAttributes: ImageAttributes) {
            imageAttributes.image = image
            imageAttributes.originalImage = originalImage
            imageAttributes.scale = scale
            imageAttributes.xWidth = position.width
            imageAttributes.yHeight = position.height
        }
        
        func loadImageAttributes(_ imageAttributes: ImageAttributes) {
            self.image = imageAttributes.image
            self.originalImage = imageAttributes.originalImage
            self.scale = imageAttributes.scale
            self.xWidth = imageAttributes.position.width
            self.yHeight = imageAttributes.position.height
        }
    }
}
