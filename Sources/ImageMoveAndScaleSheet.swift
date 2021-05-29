//
//  ImageMoveAndScaleSheet.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 03/01/21.
//

import SwiftUI

/**
A View that allows a selected image to be moved and scaled by the user.

# Bindings
 This View has four Bindings:
1. originalImage
2. originalPosition
3. originalZoom
4. processedImage

# ORIGINAL IMAGE
is the original image `UIImage` used to created the cropped UIImage.
 
# ORIGINAL POSITION
is the position `CGSize` the originalImage should be displayed. If the image is received from a previous "save", for example from CoreData, this will help position the image as it was when the cropped image was made.
 
# ORIGINAL ZOOM
is the scale `CGFloat` at which the cropped image was made. It is also used to position the image as the user would expect after loading it from a persistent state.
 
# PROCESSED IMAGE
 is the image `UIImage` after it has been cropped according to the position and scale determined by the user.
 
 It is common to save all of these properties in a persistent state. For example
 ```
 private func saveContactImage() {
     
     guard let inputImage = inputImage else { return }
     
     if contact.picture != nil {
         contact.picture!.image = inputImage
         contact.picture!.originalImage = originalImage!
         contact.picture!.scale = zoom!
         contact.picture!.xWidth = Double(position!.width)
         contact.picture!.yHeight = Double(position!.height)
         
     } else {
         
         let newContactImage = ContactImage(context: contact.managedObjectContext!)
         
         if originalImage != nil && zoom != nil && position != nil {
             newContactImage.image = inputImage
             newContactImage.originalImage = originalImage!
             newContactImage.scale = zoom!
             newContactImage.xWidth = Double(position!.width)
             newContactImage.yHeight = Double(position!.height)
             newContactImage.contact = contact
         }
     }
     
     do {
         try viewContext.save()
         viewContext.refresh(contact, mergeChanges: true)
     } catch {
         errorAlertTitle = (error as? LocalizedError)?.errorDescription ?? "An error occurred"
         errorAlertIsPresented = true
     }
 }
 ```
 
 
 
*/
struct ImageMoveAndScaleSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.verticalSizeClass) var sizeClass
    
    @StateObject var orientation = DeviceOrientation()
    
    @State private var isShowingImagePicker = false
    
    ///The cropped image is what will be sent back to the parent view.
    ///It should be the part of the image in the square defined by the
    ///cutout circle's diamter. See below, the cutout circle has an "inset" value
    ///which can be changed.
    
    @Binding var originalImage: UIImage?

    @Binding var originalPosition: CGSize?
    
    @Binding var originalZoom: CGFloat?
    
    ///Default Image (SF Symbols string or Image Asset name)
    let defaultImage: Image
    
    ///The optional UIImage that is created when cropping and or scaling the original image when
    ///[processImage](x-source-tag://processImage) is run.
    @Binding var processedImage: UIImage?
    
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
    
    
    //Localized stirngs
    let moveAndScale = NSLocalizedString("Move and Scale", comment: "indicate that the user may use gestures to move and or scale the image")
    let selectPhoto = NSLocalizedString("Select a photo by tapping the icon below", comment: "indicate that the user may select a photo by tapping on the green icon")
    let cancelSheet = NSLocalizedString("Cancel", comment: "indicate that the user cancel the action, closing the sheet")
    let usePhoto = NSLocalizedString("Use photo", comment: "indicate that the user may use the photo as currently displayed")

    var body: some View {
        
        ZStack {
            ZStack {
                Color.black.opacity(0.8)
                if displayedImage != nil {
                    Image(uiImage: displayedImage!)
                        .resizable()
                        .scaleEffect(zoomAmount + currentAmount)
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .offset(x: self.currentPosition.width, y: self.currentPosition.height)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                } else {
                    defaultImage
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.systemGray2)
                        .clipShape(Circle())
                        ///Padding is added if the default image is from the asset catalogue.
                        ///See line 45 in ImageAttributes.swift.
                        .padding((originalZoom == 15) ? inset - (originalZoom ?? 0.0) : 0)
                } 
            }
            
            Rectangle()
                .fill(Color.black).opacity(0.55)
                .mask(HoleShapeMask().fill(style: FillStyle(eoFill: true)))

            VStack {
                Text((displayedImage != nil) ? moveAndScale : selectPhoto )
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
                self.processImage()
                presentationMode.wrappedValue.dismiss()
            })
            { Text( usePhoto) }
            .opacity((displayedImage != nil) ? 1.0 : 0.2)
            .disabled((displayedImage != nil) ? false: true)
    }
}

