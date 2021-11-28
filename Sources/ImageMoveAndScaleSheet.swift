//
//  ImageMoveAndScaleSheet.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 03/01/21.
//

import SwiftUI

struct ImageMoveAndScaleSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.verticalSizeClass) var sizeClass
    
    @StateObject var orientation = DeviceOrientation()
    
    @StateObject var viewModel: ImageMoveAndScaleSheet.ViewModel
    
    var imageAttributes: ImageAttributes
    
    init(viewModel: ViewModel = .init(), imageAttributes: ImageAttributes) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.imageAttributes = imageAttributes
    }
    @State private var isShowingImagePicker = false
    
    @State var originalZoom: CGFloat?
    
    ///The input image is received from the ImagePicker.
    ///We will need to calculate and refer to its aspectr ratio
    ///in the functions found in the extensions file.
    @State var inputImage: UIImage?
    
    ///A `CGFloat` representing the ascpect ratio of the selected `UIImage`.
    ///
    ///This variable is necessary in order to determine how to reposition
    ///the `displayImage` as the [repositionImage](x-source-tag://repositionImage) function must know if the displayImage is "letterboxed" horizontally or vertically in order reposition correctly.
    @State var inputImageAspectRatio: CGFloat = 0.0
    
    ///The displayImage is what wee see on this view. When added from the
    ///ImapgePicker, it will be sized to fit the screen,
    ///meaning either its width will match the width of the device's screen,
    ///or its height will match the height of the device screen.
    ///This is not suitable for landscape mode or for iPads.
    @State var displayedImage: UIImage?
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
    
    ///find the length of the side of a square which will fit inside
    ///the Circle() shape of our mask to be sure all SF Symbol images fit inside.
    ///For the sake of sanity, just multiply the inset by 2.
    let defaultImageSide = (UIScreen.main.bounds.width - (30)) * CGFloat(2).squareRoot() / 2
    
    
    //Localized strings
    let moveAndScale = NSLocalizedString("Move and Scale", comment: "indicate that the user may use gestures to move and or scale the image")
    let selectPhoto = NSLocalizedString("Select a photo by tapping the icon below", comment: "indicate that the user may select a photo by tapping on the green icon")
    let cancelSheet = NSLocalizedString("Cancel", comment: "indicate that the user cancel the action, closing the sheet")
    let usePhoto = NSLocalizedString("Use photo", comment: "indicate that the user may use the photo as currently displayed")

    var body: some View {
        
        ZStack {
            ZStack {
                Color.black.opacity(0.8)
                if viewModel.originalImage != nil {
                    Image(uiImage: viewModel.originalImage!)
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
                        .foregroundColor(Color(.systemGray2))
                        ///Padding is added if the default image is from the asset catalogue.
                        ///See line 45 in ImageAttributes.swift.
                        .padding(inset * 2)
                }
            }
            
            Rectangle()
                .fill(Color.black).opacity(0.55)
                .mask(HoleShapeMask().fill(style: FillStyle(eoFill: true)))

            VStack {
                Text((viewModel.originalImage != nil) ? viewModel.moveAndScale : viewModel.selectPhoto )
                    .foregroundColor(.white)
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
                                openSystemPickerButton
                                    .padding(.trailing, 20)
                            }
                            saveButton
                        }
                        .padding(.horizontal)
                        .foregroundColor(.white)
                        if orientation.orientation == .portrait {
                            openSystemPickerButton
                        }
                    }
                }
            }
            .padding(.bottom, (orientation.orientation == .portrait) ? 20 : 4)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear(perform: {
            viewModel.loadImageAttributes(imageAttributes)
        })
        
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
        .sheet(isPresented: $isShowingImagePicker, onDismiss: loadImage) {

            ///Choose which system picker you want to use.
            ///In our experience, the PHPicker "Cancel" button may not work.
            ///Also, the PHPicker seems to result in many, many memory leaks. YMMV.

            ///Uncomment these two lines to use the PHPicker.
//            SystemPHPicker(image: self.$inputImage)
//                .accentColor(Color.systemRed)

            ///Uncomment the two lines below to use the old UIIMagePicker
            ///This picker also results in some leaks, but as far as we can tell
            ///far fewer than the PHPicker.
            SystemUIImagePicker(image: self.$inputImage)
                .accentColor(Color.systemRed)
        }
        .onAppear(perform: setCurrentImage )
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
            action: {presentationMode.wrappedValue.dismiss()},
            label: { Text( cancelSheet) })
    }
    
    private var openSystemPickerButton: some View {
        ZStack {
            Image(systemName: "circle.fill")
                .font(.custom("system", size: 45))
                .opacity(0.9)
                .foregroundColor( ( displayedImage == nil ) ? .systemGreen : .white)
            Image(systemName: "photo.on.rectangle")
                .imageScale(.medium)
                .foregroundColor(.black)
                .onTapGesture {
                    isShowingImagePicker = true
                }
        }
    }
    
    private var saveButton: some View {
        Button(
            action: {
                self.composeImageAttributes()
                presentationMode.wrappedValue.dismiss()
            })
        { Text( viewModel.usePhoto) }
            .opacity((viewModel.originalImage != nil) ? 1.0 : 0.2)
            .disabled((viewModel.originalImage != nil) ? false: true)
    }
}

struct ImageMoveAndScaleSheet_Previews: PreviewProvider {
    static var previews: some View {
        ImageMoveAndScaleSheet(viewModel: ImageMoveAndScaleSheet.ViewModel(),
                               imageAttributes: ImageAttributes(withSFSymbol: "photo.circle.fill")
        )
    }
}
