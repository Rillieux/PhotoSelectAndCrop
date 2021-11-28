//
//  ImagePane.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 18/11/21.
//

import SwiftUI

public struct ImagePane: View {
    
    @State private var isShowingPhotoSelectionSheet = false
    
    @ObservedObject public var imageAttributes: ImageAttributes
    
    @Binding var isEditMode: Bool
    
    @State private var addPhotoButtonLabel = NSLocalizedString("Add photo", comment: "indicate that a photo is not available and one should be added")
    @State private var changePhotoButtonLabel = NSLocalizedString("Change photo", comment: "indicate that a photo is available and may be changed to another")
    
    var renderingMode: SymbolRenderingMode = .monochrome
    var colors: [Color] = []
    var linearGradient: LinearGradient = LinearGradient(colors: [], startPoint: .topLeading, endPoint: .bottomTrailing)
    var isGradient: Bool = false
    ///A UIImage that is retrieved to be sent to the finalImage and displayed.
    ///It may be retrieved from the originalImage if one has been
    ///saved previously. Or it may be retrieved
    ///from the ImageMoveAndScaleSheet.
    @State private var inputImage: UIImage?
    
    public init(image: ImageAttributes, isEditMode: Binding<Bool>) {
        self._imageAttributes = ObservedObject(initialValue: image)
        self._isEditMode = isEditMode
    }
    
    public init(image: ImageAttributes, isEditMode: Binding<Bool>, renderingMode: SymbolRenderingMode) {
        self._imageAttributes = ObservedObject(initialValue: image)
        self._isEditMode = isEditMode
        self.renderingMode = renderingMode
    }
    
    public init(image: ImageAttributes, isEditMode: Binding<Bool>, renderingMode: SymbolRenderingMode, colors: [Color]) {
        self._imageAttributes = ObservedObject(initialValue: image)
        self._isEditMode = isEditMode
        self.renderingMode = renderingMode
        self.colors = []
        for color in colors {
            self.colors.append(color)
        }
    }
    
    public init(image: ImageAttributes, isEditMode: Binding<Bool>, renderingMode: SymbolRenderingMode, linearGradient: LinearGradient) {
        self._imageAttributes = ObservedObject(initialValue: image)
        self._isEditMode = isEditMode
        self.renderingMode = renderingMode
        self.linearGradient = linearGradient
        self.isGradient = true
    }
    
    private init(addPhotoText: String, changePhotoText: String, image: ImageAttributes, defaultImage: UIImage, isEditMode: Binding<Bool>) {
        self._imageAttributes = ObservedObject(initialValue: image)
        self._isEditMode = isEditMode
        self.addPhotoButtonLabel = addPhotoText
        self.changePhotoButtonLabel = changePhotoText
    }
    
    public var body: some View {
        
        VStack {
            displayImage
            Button (action: {
                self.isShowingPhotoSelectionSheet = true
            }, label: {
                if imageAttributes.originalImage != nil {
                    Text(changePhotoButtonLabel)
                        .font(.footnote)
                } else {
                    Text(addPhotoButtonLabel)
                        .font(.footnote)
                }
                
            })
                .opacity(isEditMode ? 1.0 : 0.0)
        }
        .fullScreenCover(isPresented: $isShowingPhotoSelectionSheet) {
            ImageMoveAndScaleSheet(imageAttributes: imageAttributes)
        }
    }
    
    ///A View that "displays" the image.
    ///
    /// - Note: This requires the `inputImage` be viable.
    private var displayImage: some View {
        
        imageAttributes.image
            .resizable()
            .symbolRenderingMode(renderingMode)
            .modifier(RenderingForegroundStyle(colors: colors, isGradient: isGradient, linearGradient: linearGradient))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .scaledToFill()
            .aspectRatio(contentMode: .fit)
            .modifier(ClipCircleOrRect(circle: (imageAttributes.originalImage == nil) ? false : true ))
            .shadow(radius: (imageAttributes.originalImage == nil) ? 0 : 4)
        
    }
    
    private struct ClipCircleOrRect: ViewModifier {
        let circle: Bool
        func body(content: Content) -> some View {
            if circle {
                content.clipShape(Circle())
            } else {
                content.clipShape(Rectangle())
            }
        }
    }
    
    
}

struct ImagePane_Previews: PreviewProvider {

    static var previews: some View {

        let placeholder = ImageAttributes(withSFSymbol: "person.crop.circle.fill")

        ImagePane(image: placeholder, isEditMode: .constant(false), renderingMode: .palette, colors: [.blue, .white])
            .frame(width: 200, height: 200, alignment: .center)
            .padding()
            .previewLayout(.sizeThatFits)
            .background(.gray)
        
        ImagePane(image: placeholder, isEditMode: .constant(true), renderingMode: .monochrome, linearGradient: LinearGradient(colors: [.white, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 200, height: 200, alignment: .center)
            .padding()
            .previewLayout(.sizeThatFits)
            .background(.gray)
        
    }
}
