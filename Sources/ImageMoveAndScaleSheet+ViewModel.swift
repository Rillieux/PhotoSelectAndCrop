//
//  ImageMoveAndScaleSheet+ViewModel.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 22/11/21.
//

import SwiftUI
import Observation

extension ImageMoveAndScaleSheet {

    @Observable @MainActor
    final class ViewModel {

        var image = Image(systemName: "star.fill")
        var originalImage: UIImage?
        var scale: CGFloat = 1.0
        var xWidth: CGFloat = 0.0
        var yHeight: CGFloat = 0.0
        var position: CGSize {
            CGSize(width: xWidth, height: yHeight)
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
