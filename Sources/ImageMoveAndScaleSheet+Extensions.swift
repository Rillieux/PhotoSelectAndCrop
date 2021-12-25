//
//  ImageMoveAndScaleSheet+Extensions.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 18/11/21.
//

import SwiftUI


///The functions in this file reltae to positioning the original image in the "viewfinder"
///(the HoleShapeMask).

extension ImageMoveAndScaleSheet {
    
    /// Loads an image selected by the user from an ImagePicker with access to the user's photo library.
    ///
    /// First, we want to measure the image top imput and determine its aspect ratio.
    func loadImage() {
        guard let inputImage = inputImage else { return }
        let w = inputImage.size.width
        let h = inputImage.size.height
        viewModel.originalImage = inputImage
        inputImageAspectRatio = w / h
        resetImageOriginAndScale()
    }
    
    
    ///Loads the current image when the view appears.
    func setCurrentImage() {
        guard let currentImage = viewModel.originalImage else { return }
        let w = currentImage.size.width
        let h = currentImage.size.height
        inputImage = currentImage
        inputImageAspectRatio = w / h
        currentPosition = imageAttributes.position
        newPosition = imageAttributes.position
        zoomAmount = imageAttributes.scale
        viewModel.originalImage = currentImage
        repositionImage()
    }
        
    ///A CGFloat used to determine the aspect ratio of the device screen
    ///in its current orientation.
    ///
    ///The displayImage will size to fit the screen.
    ///But we need to know the width and height of
    ///the screen to size it appropriately.
    ///Double-tapping the image will also set it
    ///as it was sized originally upon loading.
    private func getAspect() -> CGFloat {
        let screenAspectRatio = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        return screenAspectRatio
    }
    
    
    ///Positions the image selected to fit the screen.
    func resetImageOriginAndScale() {
        print("reposition")
        let screenAspect: CGFloat = getAspect()

        withAnimation(.easeInOut){
            if inputImageAspectRatio >= screenAspect {
                displayW = UIScreen.main.bounds.width
                displayH = displayW / inputImageAspectRatio
            } else {
                displayH = UIScreen.main.bounds.height
                displayW = displayH * inputImageAspectRatio
            }
            currentAmount = 0
            zoomAmount = 1
            currentPosition = .zero
            newPosition = .zero
        }
    }
    
    /// - Tag: repositionImage
    func repositionImage() {
        
        ///Setting the display width and height so the imputImage fits the screen
        ///orientation.
        let screenAspect: CGFloat = getAspect()
        let diameter = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        
        if screenAspect <= 1.0 {
            if inputImageAspectRatio > screenAspect {
                displayW = diameter * zoomAmount
                displayH = displayW / inputImageAspectRatio
            } else {
                displayH = UIScreen.main.bounds.height * zoomAmount
                displayW = displayH * inputImageAspectRatio
            }
        } else {
            if inputImageAspectRatio < screenAspect {
                displayH = diameter * zoomAmount
                displayW = displayH * inputImageAspectRatio
            } else {
                displayW = UIScreen.main.bounds.width * zoomAmount
                displayH = displayW / inputImageAspectRatio
            }
        }
        
        horizontalOffset = (displayW - diameter ) / 2
        verticalOffset = ( displayH - diameter) / 2

        ///Keep the user from zooming too far in. Adjust as required in your individual project.
        if zoomAmount > 4.0 {
                zoomAmount = 4.0
        }
        
        ///If the view which presents the ImageMoveAndScaleSheet is embeded in a NavigationView then the vertical offset is off.
        ///A value of 0.0 appears to work when the view is not embeded in a NAvigationView().

        ///When it is embedded in a NvaigationView, a value of 4.0 seems to keep images displaying as expected.
        ///This appears to be a SwiftUI bug. So, we "pad" the function with this "adjust". YMMV.

        let adjust: CGFloat = 0.0

        ///The following if statements keep the image filling the circle cutout in at least one dimension.
        if displayH >= diameter {
            if newPosition.height > verticalOffset {
                print("1. newPosition.height > verticalOffset")
                    newPosition = CGSize(width: newPosition.width, height: verticalOffset - adjust + inset)
                    currentPosition = CGSize(width: newPosition.width, height: verticalOffset - adjust + inset)
            }
            
            if newPosition.height < ( verticalOffset * -1) {
                print("2. newPosition.height < ( verticalOffset * -1)")
                    newPosition = CGSize(width: newPosition.width, height: ( verticalOffset * -1) - adjust - inset)
                    currentPosition = CGSize(width: newPosition.width, height: ( verticalOffset * -1) - adjust - inset)
            }
            
        } else {
            print("else: H")
                newPosition = CGSize(width: newPosition.width, height: 0)
                currentPosition = CGSize(width: newPosition.width, height: 0)
        }
        
        if displayW >= diameter {
            if newPosition.width > horizontalOffset {
                print("3. newPosition.width > horizontalOffset")
                    newPosition = CGSize(width: horizontalOffset + inset, height: newPosition.height)
                    currentPosition = CGSize(width: horizontalOffset + inset, height: currentPosition.height)
            }
            
            if newPosition.width < ( horizontalOffset * -1) {
                print("4. newPosition.width < ( horizontalOffset * -1)")
                    newPosition = CGSize(width: ( horizontalOffset * -1) - inset, height: newPosition.height)
                    currentPosition = CGSize(width: ( horizontalOffset * -1) - inset, height: currentPosition.height)

            }
            
        } else {
            print("else: W")
                newPosition = CGSize(width: 0, height: newPosition.height)
                currentPosition = CGSize(width: 0, height: newPosition.height)
        }

        ///This statement is needed in case of a screenshot.
        ///That is, in case the user chooses a photo that is the exact size of the device screen.
        ///Without this function, such an image can be shrunk to less than the
        ///size of the cutrout circle and even go negative (inversed).
        ///If "processImage()" is run in this state, there is a fatal error. of a nil UIImage.
        ///
        if displayW < diameter - inset && displayH < diameter - inset {
            resetImageOriginAndScale()
        }
    }
    
    /// - Tag: processImage
    ///A function to save a process the image.
    ///
    /// - Note: But if the user saves the image in one mode and them opens it in another, the
    ///scale and size will be slightly off.
    ///
    func composeImageAttributes() {
        
        let scale = (inputImage?.size.width)! / displayW
        let originAdjustment = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let diameter = ( originAdjustment - inset * 2 ) * scale
        
        let xPos = ( ( ( displayW - originAdjustment ) / 2 ) + inset + ( currentPosition.width * -1 ) ) * scale
        let yPos = ( ( ( displayH - originAdjustment ) / 2 ) + inset + ( currentPosition.height * -1 ) ) * scale
        
        let tempUIImage: UIImage = croppedImage(from: inputImage!, croppedTo: CGRect(x: xPos, y: yPos, width: diameter, height: diameter))
        
        imageAttributes.image = Image(uiImage: tempUIImage)
        imageAttributes.originalImage = inputImage
        imageAttributes.croppedImage = tempUIImage
        imageAttributes.scale = zoomAmount
        imageAttributes.xWidth = currentPosition.width
        imageAttributes.yHeight = currentPosition.height
    }
}
