//
//  LocalizedStrings.swift
//  PhotoSelectAndCrop
//

import Foundation

///The single source of truth for the package's user-facing strings.
///
///Strings are resolved against `Bundle.module` so that the localizations
///bundled with this package (en, fr) are actually used at runtime.
enum LocalizedStrings {

    static let moveAndScale = String(localized: "Move and Scale", bundle: .module,
        comment: "indicate that the user may use gestures to move and or scale the image")

    static let selectPhoto = String(localized: "Select a photo by tapping the icon below", bundle: .module,
        comment: "indicate that the user may select a photo by tapping on the green icon")

    static let cancel = String(localized: "Cancel", bundle: .module,
        comment: "indicate that the user cancel the action, closing the sheet")

    static let usePhoto = String(localized: "Use photo", bundle: .module,
        comment: "indicate that the user may use the photo as currently displayed")

    static let addPhoto = String(localized: "Add photo", bundle: .module,
        comment: "indicate that a photo is not available and one should be added")

    static let changePhoto = String(localized: "Change photo", bundle: .module,
        comment: "indicate that a photo is available and may be changed to another")
}
