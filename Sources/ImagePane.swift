//
//  ImagePane.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 18/11/21.
//

import SwiftUI

public struct ImagePane: View {

    @State private var isShowingPhotoSelectionSheet = false

    public var imageAttributes: ImageAttributes

    @Binding var isEditMode: Bool

    var renderingMode: SymbolRenderingMode
    var colors: [Color]
    var linearGradient: LinearGradient
    var isGradient: Bool

    public init(image: ImageAttributes,
                isEditMode: Binding<Bool>,
                renderingMode: SymbolRenderingMode = .monochrome,
                colors: [Color] = [],
                linearGradient: LinearGradient? = nil) {
        self.imageAttributes = image
        self._isEditMode = isEditMode
        self.renderingMode = renderingMode
        self.colors = colors
        self.linearGradient = linearGradient
            ?? LinearGradient(colors: [], startPoint: .topLeading, endPoint: .bottomTrailing)
        self.isGradient = linearGradient != nil
    }

    public var body: some View {

        VStack {
            displayImage
            Button (action: {
                self.isShowingPhotoSelectionSheet = true
            }, label: {
                if imageAttributes.originalImage != nil {
                    Text(LocalizedStrings.changePhoto)
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text(LocalizedStrings.addPhoto)
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                }
            })
                .opacity(isEditMode ? 1.0 : 0.0)
        }
        .fullScreenCover(isPresented: $isShowingPhotoSelectionSheet) {
            ImageMoveAndScaleSheet(imageAttributes: imageAttributes)
        }
    }

    ///A View that "displays" the image.
    private var displayImage: some View {

        imageAttributes.image
            .resizable()
            .symbolRenderingMode(renderingMode)
            .modifier(RenderingForegroundStyle(colors: colors, isGradient: isGradient, linearGradient: linearGradient))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .scaledToFill()
            .aspectRatio(contentMode: .fit)
            .clipShape(Circle())
            .shadow(radius: (imageAttributes.originalImage == nil) ? 0 : 4)
    }
}

struct ImagePane_Previews: PreviewProvider {

    static var previews: some View {

        let placeholder = ImageAttributes(withSFSymbol: "photo.circle")
        let size = 150.0
        ImagePane(image: placeholder, isEditMode: .constant(true))
            .frame(width: size, height: size, alignment: .center)
            .foregroundStyle(.pink.opacity(0.25))
            .padding()
            .previewLayout(.sizeThatFits)
            .background(.white)

        ImagePane(image: placeholder, isEditMode: .constant(false), renderingMode: .palette, colors: [.blue, .white])
            .frame(width: size, height: size, alignment: .center)
            .padding()
            .previewLayout(.sizeThatFits)
            .background(.gray)

        ImagePane(image: placeholder, isEditMode: .constant(true), renderingMode: .monochrome, linearGradient: LinearGradient(colors: [.yellow, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size, alignment: .center)
            .padding()
            .previewLayout(.sizeThatFits)
            .background(.black)
    }
}
