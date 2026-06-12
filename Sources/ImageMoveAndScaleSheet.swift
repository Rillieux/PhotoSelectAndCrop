//
//  ImageMoveAndScaleSheet.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 03/01/21.
//

import SwiftUI
import PhotosUI

@MainActor
struct ImageMoveAndScaleSheet: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject var orientation = DeviceOrientation()

    ///Internal rather than private because the gesture/crop helpers in
    ///ImageMoveAndScaleSheet+Extensions.swift live in a separate file.
    @State var viewModel = ViewModel()

    var imageAttributes: ImageAttributes

    init(imageAttributes: ImageAttributes) {
        self.imageAttributes = imageAttributes
    }

    @State private var isShowingPhotoPicker = false

    ///The item selected in the photo picker, whose image data
    ///is loaded asynchronously into `inputImage`.
    @State private var selectedItem: PhotosPickerItem?

    ///The input image is received from the photo picker.
    ///We will need to calculate and refer to its aspect ratio
    ///in the functions found in the extensions file.
    @State var inputImage: UIImage?

    ///A `CGFloat` representing the aspect ratio of the selected `UIImage`.
    ///
    ///This variable is necessary in order to determine how to reposition
    ///the `displayImage` as the [repositionImage](x-source-tag://repositionImage) function must know if the displayImage is "letterboxed" horizontally or vertically in order reposition correctly.
    @State var inputImageAspectRatio: CGFloat = 0.0

    ///The displayImage is what we see on this view. When added from the
    ///photo picker, it will be sized to fit the screen,
    ///meaning either its width will match the width of the device's screen,
    ///or its height will match the height of the device screen.
    ///This is not suitable for landscape mode or for iPads.
    @State var displayW: CGFloat = 0.0
    @State var displayH: CGFloat = 0.0

    //Zoom and Drag ...

    @State var currentAmount: CGFloat = 0
    @State var zoomAmount: CGFloat = 1.0
    @State var currentPosition: CGSize = .zero
    @State var newPosition: CGSize = .zero
    @State var horizontalOffset: CGFloat = 0.0
    @State var verticalOffset: CGFloat = 0.0

    //Local variables

    ///A CGFloat used to "pad" the circle set into the view.
    let inset: CGFloat = 15

    var body: some View {

        ZStack {
            ZStack {
                Color.black.opacity(0.8)
                if let originalImage = viewModel.originalImage {
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaleEffect(zoomAmount + currentAmount)
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .offset(x: self.currentPosition.width, y: self.currentPosition.height)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                } else {
                    viewModel.image
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color(uiColor: .systemGray2))
                        ///Padding is added if the default image is from the asset catalogue.
                        ///See the init(withImage:) in ImageAttributes.swift.
                        .padding(inset * 2)
                }
            }

            Rectangle()
                .fill(Color.black).opacity(0.55)
                .mask(HoleShapeMask().fill(style: FillStyle(eoFill: true)))

            VStack {
                Text((viewModel.originalImage != nil) ? LocalizedStrings.moveAndScale : LocalizedStrings.selectPhoto)
                    .foregroundStyle(.white)
                    .padding(.top, 50)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity((orientation.orientation == .portrait) ? 1.0 : 0.0)

                Spacer()
                HStack{
                    ZStack {
                        HStack {
                            cancelButton
                            Spacer()
                            if orientation.orientation == .landscape {
                                openPhotoPickerButton
                                    .padding(.trailing, 20)
                            }
                            saveButton
                        }
                        .padding(.horizontal)
                        .foregroundStyle(.white)
                        if orientation.orientation == .portrait {
                            openPhotoPickerButton
                        }
                    }
                }
            }
            .padding(.bottom, (orientation.orientation == .portrait) ? 20 : 4)
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.loadImageAttributes(imageAttributes)
            setCurrentImage()
        }

        //MARK: - Gestures

        .gesture(
            MagnificationGesture()
                .onChanged { amount in
                    self.currentAmount = amount - 1
                }
                .onEnded { amount in
                    self.zoomAmount += self.currentAmount
                    if zoomAmount > 4.0 {
                        withAnimation {
                            zoomAmount = 4.0
                        }
                    }
                    self.currentAmount = 0
                    withAnimation {
                        repositionImage()
                    }
                }
        )
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                }
                .onEnded { value in
                    self.currentPosition = CGSize(width: value.translation.width + self.newPosition.width, height: value.translation.height + self.newPosition.height)
                    self.newPosition = self.currentPosition
                    withAnimation {
                        repositionImage()
                    }
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded(  { resetImageOriginAndScale() } )
        )

        //MARK: - Photo picker

        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            ///A nil newItem is our own reset below; cancelling the picker never fires onChange.
            guard let newItem else { return }
            Task {
                ///Reset the selection once loading finishes so picking
                ///the same asset a second time fires onChange again.
                ///The extra onChange(nil) this causes is swallowed by the guard above.
                defer { selectedItem = nil }
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data) else { return }
                inputImage = uiImage
                loadImage()
            }
        }
    }

    ///Sets the mask to darken the background of the displayImage.
    ///
    /// - Parameter rect: a CGRect filling the device screen.
    ///
    ///Code for mask obtained from [StackOVerflow](https://stackoverflow.com/questions/59656117/swiftui-add-inverted-mask)
    func HoleShapeMask() -> Path {
        let rect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        let insetRect = CGRect(x: inset, y: inset, width: UIScreen.main.bounds.width - ( inset * 2 ), height: UIScreen.main.bounds.height - ( inset * 2 ))
        var shape = Rectangle().path(in: rect)
        shape.addPath(Circle().path(in: insetRect))
        return shape
    }

    //MARK: - Buttons, Labels

    private var cancelButton: some View {
        Button(
            action: { dismiss() },
            label: { Text(LocalizedStrings.cancel) })
    }

    private var openPhotoPickerButton: some View {
        Button {
            isShowingPhotoPicker = true
        } label: {
            ZStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 45))
                    .opacity(0.9)
                    .foregroundStyle(Color(uiColor: .systemGreen))
                Image(systemName: "photo.on.rectangle")
                    .imageScale(.medium)
                    .foregroundStyle(.black)
            }
        }
        .accessibilityLabel(Text(LocalizedStrings.selectPhoto))
    }

    private var saveButton: some View {
        Button {
            self.composeImageAttributes()
            dismiss()
        } label: {
            Text(LocalizedStrings.usePhoto)
        }
        .opacity((viewModel.originalImage != nil) ? 1.0 : 0.2)
        .disabled(viewModel.originalImage == nil)
    }
}

struct ImageMoveAndScaleSheet_Previews: PreviewProvider {
    static var previews: some View {
        ImageMoveAndScaleSheet(imageAttributes: ImageAttributes(withSFSymbol: "photo.circle.fill"))
    }
}
