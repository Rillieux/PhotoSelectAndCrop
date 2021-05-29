//
//  SystemPHPicker.swift
//  PhotoSelectAndCrop
//
//  Created by Dave Kondris on 22/01/21.
//
import PhotosUI
import SwiftUI

///Implementation of the PHPickerViewController.
///
///This picker is the one that sandboxes the user's pictures from the application.
///
/// - Warning: This picker appears to have two large drawbacks:
///
///1. Using the PHPickerViewController appears to result in
///numerous memory leaks from the Apple code.
///
///2. It seems that the "cancel" button on this picker from Apple
///does not work. The user *must* select an image.

struct SystemPHPicker: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: SystemPHPicker
        
        init(parent: SystemPHPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            for img in results {
                guard img.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
                img.itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    guard let image = image as? UIImage else { return }
                    self.parent.image = image
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
