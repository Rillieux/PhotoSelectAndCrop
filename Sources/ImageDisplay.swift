//
//  ImageDisplay.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 26/02/21.
//

import SwiftUI

public struct ImageDisplay: View {

    @State private var isShowingPhotoSelectionSheet = false
    
    @ObservedObject var image: ImageAttributes
    
    @Binding var isEditMode: Bool
    
    @State private var addPhotoButtonLabel = NSLocalizedString("Add photo", comment: "indicate that a photo is not available and one should be added")
    @State private var changePhotoButtonLabel = NSLocalizedString("Change photo", comment: "indicate that a photo is available and may be changed to another")
    
    @State private var defaultImage: Image?
    @State private var originalImage: UIImage?
    @State private var zoom: CGFloat?
    @State private var position: CGSize?
    
    ///displayedImage is the image displayed in this view
    ///when it is available. 
    @State private var displayedImage: UIImage?
    
    ///A UIImage that is retrieved to be sent to the finalImage and displayed.
    ///It may be retrieved from the originalImage if one has been
    ///saved previously. Or it may be retrieved
    ///from the ImageMoveAndScaleSheet.
    @State private var inputImage: UIImage?
    
    public init(image: ImageAttributes, isEditMode: Binding<Bool>) {
        self.image = image
        self._originalImage = State(initialValue: image.originalImage)
        self._zoom = State(initialValue: CGFloat(image.scale))
        self._position = State(initialValue: image.position)
        self._displayedImage = State(initialValue: image.image)
        self._defaultImage = State(wrappedValue: image.swiftUIImage)
        self._isEditMode = isEditMode
    }

    private init(addPhotoText: String, changePhotoText: String, image: ImageAttributes, defaultImage: UIImage, isEditMode: Binding<Bool>) {
        self.image = image
        self._originalImage = State(initialValue: image.originalImage)
        self._zoom = State(initialValue: CGFloat(image.scale))
        self._position = State(initialValue: image.position)
        self._displayedImage = State(initialValue: image.image)
        self._defaultImage = State(wrappedValue: image.swiftUIImage)
        self._isEditMode = isEditMode
        self.addPhotoButtonLabel = addPhotoText
        self.changePhotoButtonLabel = changePhotoText
    }
    
    public var body: some View {

        VStack {
            if displayedImage != nil {
                displayImage
            } else {
                defaultImageView
            }
            Button (action: {
                self.isShowingPhotoSelectionSheet = true
            }, label: {
                if displayedImage != nil {
                    Text(changePhotoButtonLabel)
                        .font(.footnote)
                } else {
                    Text(addPhotoButtonLabel)
                        .font(.footnote)
                }
                    
            })
            .opacity(isEditMode ? 1.0 : 0.0)
        }
        .statusBar(hidden: isShowingPhotoSelectionSheet)
        .fullScreenCover(isPresented: $isShowingPhotoSelectionSheet, onDismiss: loadImage) {
            ImageMoveAndScaleSheet(originalImage: $originalImage, originalPosition: $position, originalZoom: $zoom, defaultImage: image.swiftUIImage ?? Image(systemName: "photo"), processedImage: $inputImage)
        }
    }
    
    ///A View that "displays" the image.
    ///
    /// - Note: This requires the `inputImage` be viable.
    private var displayImage: some View {
        Image(uiImage: displayedImage!)
            .resizable()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .scaledToFill()
            .aspectRatio(contentMode: .fit)
            .clipShape(Circle())
            .shadow(radius: 4)
    }
    
    ///A View which shows a "default" image when there is nothing else to display.
    ///Alter to suit your project specifications.
    private var defaultImageView: some View {
        image.swiftUIImage?
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .aspectRatio(contentMode: .fit)
            .clipShape(Circle())
            .foregroundColor(.gray)
    }
    
    ///The function that loads the selected image into the inputImage
    ///State variable.
    func loadImage() {
        guard let inputImage = inputImage else { return }
        displayedImage = inputImage
    }
}
