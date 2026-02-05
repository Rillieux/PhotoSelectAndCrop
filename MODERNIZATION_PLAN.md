# PhotoSelectAndCrop — SwiftUI Modernization Plan

## Dependency Graph (Build Order)

Understanding the dependency graph is critical for ordering changes safely.
Each layer depends only on layers above it.

```
Layer 0: Package.swift
    └── Sets swift-tools-version and iOS platform target.
        Everything below depends on this.

Layer 1: Standalone utilities (no internal dependencies)
    ├── Color+Extensions.swift    → used by ImageMoveAndScaleSheet
    ├── Image+Extensions.swift    → UNUSED (dead code)
    ├── ImageManipulation.swift   → used by ImageMoveAndScaleSheet+Extensions
    └── ViewModifiers.swift       → used by ImagePane

Layer 2: Data models (no internal dependencies)
    ├── ImageAttributes.swift     → used by ImagePane, ImageMoveAndScaleSheet,
    │                                ViewModel, Extensions
    └── DeviceOrientation.swift   → used by ImageMoveAndScaleSheet

Layer 3: Photo pickers (no internal dependencies)
    ├── SystemImagePicker.swift   → used by ImageMoveAndScaleSheet
    └── SystemPHPicker.swift      → used by ImageMoveAndScaleSheet (commented out)

Layer 4: ViewModel (depends on Layer 2)
    └── ImageMoveAndScaleSheet+ViewModel.swift → used by ImageMoveAndScaleSheet

Layer 5: Core sheet view (depends on all above)
    ├── ImageMoveAndScaleSheet.swift
    └── ImageMoveAndScaleSheet+Extensions.swift

Layer 6: Public entry point (depends on Layer 2 + Layer 5)
    └── ImagePane.swift
```

## Guiding Principles

1. **Bottom-up**: modify leaf dependencies first so nothing breaks mid-way.
2. **Coordinated steps**: when a change spans multiple files (e.g. `@Observable`
   migration), all affected files are modified in a single step.
3. **Comment-out, don't delete**: old code is commented out with an explanation
   of *why* it is being replaced, so reviewers can see the before/after.
4. **Compilable after every step**: each step leaves the project in a state
   that compiles and runs.

---

## Step 1 — Update `Package.swift`

**File:** `Package.swift`

**Why:** Every subsequent step depends on modern Swift features and iOS APIs.
We need `swift-tools-version: 5.9` minimum for `#Preview` and `@Observable`,
and `iOS(.v17)` minimum for the `@Observable` macro and deprecation-free APIs.
`PhotosPicker` is available from iOS 16, but since we also want `@Observable`
we target iOS 17.

### Changes

Comment out old values, add new ones:

```swift
// COMMENTED OUT — swift-tools-version:5.3 is from 2020 and does not support
// the #Preview macro, @Observable, or modern Swift concurrency features.
// swift-tools-version:5.3

// REPLACEMENT — 5.9 is the minimum version that supports the @Observable
// macro and the #Preview macro.
swift-tools-version:5.9
```

```swift
platforms: [
    // COMMENTED OUT — iOS 15.0 predates native PhotosPicker (iOS 16),
    // @Observable (iOS 17), and many other APIs this modernization requires.
    // .iOS("15.0")

    // REPLACEMENT — iOS 17.0 is the minimum version needed for @Observable,
    // UIGraphicsImageRenderer improvements, and deprecation-free code.
    .iOS(.v17)
],
```

### Verification
- `swift build` should succeed with no source changes (existing code compiles
  fine under 5.9 / iOS 17).

---

## Step 2 — Fix `ImageManipulation.swift` (Cropping)

**File:** `Sources/ImageManipulation.swift`

**Why:** This is a leaf utility with no internal dependents other than
`composeImageAttributes()`. Fixing it first means the crop pipeline is
correct before we touch the UI layer.

### Issues addressed
| # | Issue |
|---|-------|
| 1 | `UIGraphicsBeginImageContext` deprecated in iOS 17 |
| 2 | Creates a 1x bitmap context — loses Retina resolution |
| 3 | Force-unwrap `subImage!` crashes if context fails |

### Changes

Comment out the entire existing function body. Replace with a new
implementation using `UIGraphicsImageRenderer`:

```swift
/// Crops a UIImage to the specified rectangle.
///
/// - Parameters:
///   - image: The original full-size image.
///   - rect: The rectangle (in the image's point coordinate space) to crop to.
/// - Returns: A new UIImage containing only the cropped region, or the
///   original image if cropping fails.
///
/// ## Why this was rewritten
/// The previous implementation used `UIGraphicsBeginImageContext` which:
/// - Was deprecated in iOS 17.
/// - Created a 1x-scale bitmap, discarding Retina resolution on 2x/3x devices.
/// - Force-unwrapped the result, risking a crash on failure.
///
/// The replacement uses `UIGraphicsImageRenderer` which:
/// - Automatically matches the device's native scale (Retina-safe).
/// - Handles color spaces and traits correctly.
/// - Returns a non-optional UIImage (no force-unwrap needed).
func croppedImage(from image: UIImage, croppedTo rect: CGRect) -> UIImage {

    // COMMENTED OUT — deprecated UIGraphicsBeginImageContext approach.
    // This created a 1x context (not Retina-aware), used deprecated APIs
    // removed in iOS 17, and force-unwrapped the result.
    //
    // UIGraphicsBeginImageContext(rect.size)
    // let context = UIGraphicsGetCurrentContext()
    // let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y,
    //                       width: image.size.width, height: image.size.height)
    // context?.clip(to: CGRect(x: 0, y: 0,
    //                          width: rect.size.width, height: rect.size.height))
    // image.draw(in: drawRect)
    // let subImage = UIGraphicsGetImageFromCurrentImageContext()
    // UIGraphicsEndImageContext()
    // return subImage!

    // REPLACEMENT — UIGraphicsImageRenderer is the modern API (iOS 10+).
    // It respects the device's screen scale, so cropped images retain full
    // Retina resolution. The format is configured to match the source image's
    // scale factor rather than defaulting to the screen scale.
    let format = UIGraphicsImageRendererFormat()
    format.scale = image.scale

    // Guard against degenerate crop rects that would produce a zero-size image.
    guard rect.width > 0, rect.height > 0 else {
        return image
    }

    let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
    return renderer.image { _ in
        // Draw the full image offset so that the crop rect's origin aligns
        // with (0,0) in the renderer's coordinate space.
        let drawRect = CGRect(x: -rect.origin.x, y: -rect.origin.y,
                              width: image.size.width, height: image.size.height)
        image.draw(in: drawRect)
    }
}
```

### Verification
- Builds cleanly. The function signature is unchanged, so all callers
  (`composeImageAttributes`) continue to work.

---

## Step 3 — Comment out `Color+Extensions.swift`

**File:** `Sources/Color+Extensions.swift`

**Why:** Since iOS 15, SwiftUI's `Color` provides direct equivalents for most
system colors (e.g. `Color.red`, `Color.gray`). Since iOS 17, even the
semantic variants (fills, backgrounds) are accessible via `ShapeStyle`.
Most of these bridging wrappers are unnecessary.

### Changes

Comment out every color property that has a direct SwiftUI equivalent.
Keep any that do **not** have a one-to-one SwiftUI replacement (the gray
variants `systemGray2` through `systemGray6` and the semantic fills/
backgrounds still require the UIColor bridge as of iOS 17).

Add a block comment at the top of the file:

```swift
// NOTE: Many of these Color extensions were written when SwiftUI lacked
// direct access to UIKit system colors. As of iOS 15+, most standard
// colors are available natively in SwiftUI:
//
//   Color.red, Color.blue, Color.pink, Color.teal, Color.green,
//   Color.indigo, Color.orange, Color.purple, Color.yellow, Color.gray
//
// The following properties are COMMENTED OUT because they duplicate
// built-in SwiftUI colors. The remaining properties (gray2–gray6,
// label variants, fill variants, background variants) are kept because
// SwiftUI does not yet expose direct equivalents for them.
```

Specifically comment out (with individual reason):
- `systemRed`, `systemBlue`, `systemPink`, `systemTeal`, `systemGreen`,
  `systemIndigo`, `systemOrange`, `systemPurple`, `systemYellow`, `systemGray`

Keep (they have no direct SwiftUI `Color` equivalent):
- `label`, `secondaryLabel`, `tertiaryLabel`, `quaternaryLabel`
- `systemFill`, `secondarySystemFill`, `tertiarySystemFill`,
  `quaternarySystemFill`
- `systemBackground`, `secondarySystemBackground`,
  `tertiarySystemBackground`
- `systemGroupedBackground`, `secondarySystemGroupedBackground`,
  `tertiarySystemGroupedBackground`
- `systemGray2` through `systemGray6`

### Downstream impact
After commenting out `systemRed`, `systemGreen`, `systemGray2`:
- `ImageMoveAndScaleSheet.swift:189` uses `Color.systemRed` → will be updated
  in Step 9 to use `Color.red`.
- `ImageMoveAndScaleSheet.swift:221` uses `.systemGreen` → this one is kept.
- `ImageMoveAndScaleSheet.swift:94` uses `Color(.systemGray2)` → this uses
  the `Color(UIColor)` initializer directly, not our extension, so it is
  unaffected.

**IMPORTANT**: Because `Color.systemRed` and `Color.systemGreen` are used in
`ImageMoveAndScaleSheet.swift`, we must update those call sites in the same
step or leave `.systemGreen` in place (it's kept above). For `.systemRed`:
- The call site is `.accentColor(Color.systemRed)` on line 189.
- We will note this as a forward dependency and fix it in Step 9 (when we
  replace the picker sheet entirely).
- **To avoid a build break**, keep `systemRed` uncommented for now and mark it
  with a `// TODO: Remove after Step 9 replaces the picker sheet` comment.

### Verification
- Builds cleanly (no call sites reference the commented-out properties except
  `systemRed` which is temporarily kept).

---

## Step 4 — Comment out `Image+Extensions.swift`

**File:** `Sources/Image+Extensions.swift`

**Why:** The `imageDisplayStyle()` function is never called anywhere in the
codebase. It is dead code.

### Changes

Comment out the entire extension body:

```swift
// COMMENTED OUT — this extension is unused anywhere in the package.
// The ImagePane view applies these same modifiers inline on its
// `displayImage` computed property. This dead code can be removed
// in a future cleanup pass.
//
// extension Image {
//     func imageDisplayStyle() -> some View {
//         return self
//             .resizable()
//             .scaledToFill()
//             .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//             .aspectRatio(contentMode: .fit)
//             .clipShape(Circle())
//             .foregroundColor(.gray)
//     }
// }
```

### Verification
- Builds cleanly (no callers).

---

## Step 5 — Migrate data models to `@Observable` (coordinated)

**Files modified together:**
1. `Sources/ImageAttributes.swift`
2. `Sources/DeviceOrientation.swift`
3. `Sources/ImageMoveAndScaleSheet+ViewModel.swift`
4. `Sources/ImageMoveAndScaleSheet.swift` (property declarations only)
5. `Sources/ImagePane.swift` (property declaration only)

**Why:** `ObservableObject` + `@Published` is the Combine-era observation
system. The `@Observable` macro (iOS 17 / Swift 5.9) provides more granular
view updates (only re-renders views that read changed properties), eliminates
boilerplate, and removes the need for `@StateObject` / `@ObservedObject`.

All five files must change in one step because the type conformance and the
property wrappers at the usage site must agree.

### 5a. `ImageAttributes.swift`

Comment out the `ObservableObject` conformance and all `@Published` wrappers.
Add the `@Observable` macro. Add `import Observation`.

```swift
import SwiftUI
import Observation

/// @Observable replaces ObservableObject. Benefits:
/// - No need for @Published on each property.
/// - SwiftUI tracks which properties each view actually reads, so views
///   only re-render when the specific properties they use change.
/// - Consumers use @State (for ownership) or plain properties (for
///   references) instead of @StateObject / @ObservedObject.

// COMMENTED OUT — ObservableObject is the Combine-based observation system.
// It requires @Published on every property and causes full-view re-renders
// when *any* published property changes, regardless of whether the view
// actually reads it.
// public class ImageAttributes: ObservableObject {

@Observable
public class ImageAttributes {

    // COMMENTED OUT — @Published is not used with @Observable.
    // The @Observable macro automatically generates observation tracking
    // for all stored properties.
    // @Published public var image: Image
    // @Published public var originalImage: UIImage?
    // @Published public var croppedImage: UIImage?
    // @Published public var scale: CGFloat
    // @Published public var xWidth: CGFloat
    // @Published public var yHeight: CGFloat

    // REPLACEMENT — plain stored properties. The @Observable macro
    // synthesizes willSet/didSet observation hooks automatically.
    public var image: Image
    public var originalImage: UIImage?
    public var croppedImage: UIImage?
    public var scale: CGFloat
    public var xWidth: CGFloat
    public var yHeight: CGFloat

    // position computed property and all initializers remain unchanged.
    ...
}
```

### 5b. `DeviceOrientation.swift`

Comment out the entire `ObservableObject`-based class. Replace with an
`@Observable` version. Also add a comment explaining that an alternative
approach using SwiftUI environment values exists.

```swift
import UIKit
import Observation

// NOTE: An alternative to this class is to use SwiftUI's built-in
// @Environment(\.horizontalSizeClass) and @Environment(\.verticalSizeClass)
// environment values, which provide layout-appropriate size information
// without manual UIDevice notification handling. Consider replacing this
// class entirely with environment-based checks in a future refactor.

// COMMENTED OUT — ObservableObject version used Combine's assign(to:)
// operator. The @Observable macro replaces this pattern.
// final class DeviceOrientation: ObservableObject {
//     enum Orientation {
//         case portrait
//         case landscape
//     }
//     @Published private(set) var orientation: Orientation = ...
//     init() {
//         NotificationCenter.default.publisher(...)
//             .compactMap { ... }
//             .assign(to: &$orientation)
//     }
// }

// REPLACEMENT — uses @Observable instead of ObservableObject.
// Since @Observable does not use Combine's @Published, we subscribe
// to the notification and update the property directly via sink().

import Combine

@Observable
final class DeviceOrientation {

    enum Orientation {
        case portrait
        case landscape
    }

    // The @Observable macro tracks changes to this property automatically.
    private(set) var orientation: Orientation

    // Hold the Combine subscription so it isn't deallocated.
    private var cancellable: AnyCancellable?

    init() {
        // Set initial orientation based on current device state.
        self.orientation = UIDevice.current.orientation.isLandscape
            ? .landscape : .portrait

        // Subscribe to orientation change notifications.
        // We use sink() instead of assign(to:) because @Observable
        // properties don't have Combine $projections.
        self.cancellable = NotificationCenter.default
            .publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { notification -> Orientation? in
                guard let device = notification.object as? UIDevice else {
                    return nil
                }
                if device.orientation.isPortrait { return .portrait }
                if device.orientation.isLandscape { return .landscape }
                return nil
            }
            .sink { [weak self] newOrientation in
                self?.orientation = newOrientation
            }
    }
}
```

### 5c. `ImageMoveAndScaleSheet+ViewModel.swift`

Comment out `ObservableObject` conformance and `@Published`. Add `@Observable`.

```swift
import SwiftUI
import Observation

extension ImageMoveAndScaleSheet {

    // COMMENTED OUT — ObservableObject version.
    // class ViewModel: ObservableObject {
    //     @Published var image = Image(systemName: "star.fill")
    //     @Published var originalImage: UIImage?
    //     @Published var scale: CGFloat = 1.0
    //     @Published var xWidth: CGFloat = 0.0
    //     @Published var yHeight: CGFloat = 0.0
    //     ...
    // }

    // REPLACEMENT — @Observable provides automatic observation tracking
    // without @Published wrappers or ObservableObject conformance.
    @Observable
    class ViewModel {
        var image = Image(systemName: "star.fill")
        var originalImage: UIImage?
        var scale: CGFloat = 1.0
        var xWidth: CGFloat = 0.0
        var yHeight: CGFloat = 0.0

        // Computed property, localized strings, and functions
        // remain unchanged.
        ...
    }
}
```

### 5d. `ImageMoveAndScaleSheet.swift` (property wrappers only)

Comment out `@StateObject` declarations, replace with `@State`:

```swift
// COMMENTED OUT — @StateObject is the ObservableObject-era wrapper for
// creating owned observable instances. With @Observable, use @State instead.
// @StateObject var orientation = DeviceOrientation()
// @StateObject var viewModel: ImageMoveAndScaleSheet.ViewModel

// REPLACEMENT — @State now works with @Observable classes in iOS 17+.
// It provides the same ownership semantics as @StateObject did.
@State var orientation = DeviceOrientation()
@State var viewModel: ImageMoveAndScaleSheet.ViewModel
```

Update the `init` to use `@State` initializer syntax:

```swift
init(viewModel: ViewModel = .init(), imageAttributes: ImageAttributes) {
    // COMMENTED OUT — StateObject wrappedValue initializer.
    // _viewModel = StateObject(wrappedValue: viewModel)

    // REPLACEMENT — @State can be initialized directly for @Observable types.
    _viewModel = State(initialValue: viewModel)
    self.imageAttributes = imageAttributes
}
```

### 5e. `ImagePane.swift` (property wrapper only)

```swift
// COMMENTED OUT — @ObservedObject is the ObservableObject-era wrapper for
// externally-owned observable instances. With @Observable, observation
// is automatic — no property wrapper is needed for read-only access.
// @ObservedObject public var imageAttributes: ImageAttributes

// REPLACEMENT — plain property. The @Observable macro on ImageAttributes
// ensures SwiftUI automatically tracks which properties this view reads
// and re-renders only when those specific properties change.
public var imageAttributes: ImageAttributes
```

Update all `init` methods to use direct assignment instead of
`ObservedObject(initialValue:)`:

```swift
// COMMENTED OUT:
// self._imageAttributes = ObservedObject(initialValue: image)

// REPLACEMENT:
self.imageAttributes = image
```

### Verification
- All five files compile together. The observation behavior is identical
  but now uses the modern `@Observable` system.

---

## Step 6 — Comment out photo pickers, add `PhotosPicker`

**Files modified:**
1. `Sources/SystemImagePicker.swift` — comment out entirely
2. `Sources/SystemPHPicker.swift` — comment out entirely
3. `Sources/ImageMoveAndScaleSheet.swift` — replace picker integration

**Why:** Both `SystemUIImagePicker` and `SystemPHPicker` are
`UIViewControllerRepresentable` wrappers around UIKit view controllers.
Since iOS 16, SwiftUI provides a native `PhotosPicker` view in the `PhotosUI`
framework that eliminates the need for UIKit bridging, coordinators, and
delegates. It also eliminates the documented memory leaks and broken cancel
button.

### 6a. `SystemImagePicker.swift`

Comment out the entire file contents:

```swift
// COMMENTED OUT — SystemUIImagePicker wrapped UIImagePickerController using
// UIViewControllerRepresentable. This required a Coordinator class to act
// as UIImagePickerControllerDelegate, manual presentationMode dismissal,
// and resulted in documented memory leaks (see original line 13 comment).
//
// REPLACED BY: SwiftUI's native PhotosPicker (iOS 16+) in the PhotosUI
// framework. PhotosPicker is a pure SwiftUI view that:
// - Requires no UIViewControllerRepresentable or Coordinator.
// - Handles dismissal automatically.
// - Sandboxes photo library access (no PHPhotoLibrary permission needed).
// - Does not exhibit the memory leaks documented in this file.
//
// See ImageMoveAndScaleSheet.swift for the PhotosPicker integration.

// public struct SystemUIImagePicker: UIViewControllerRepresentable {
//     @Environment(\.presentationMode) var presentationMode
//     @Binding var image: UIImage?
//     ...entire struct...
// }
```

### 6b. `SystemPHPicker.swift`

Comment out the entire file contents (same pattern as 6a):

```swift
// COMMENTED OUT — SystemPHPicker wrapped PHPickerViewController using
// UIViewControllerRepresentable. It documented two significant issues:
// 1. Numerous memory leaks from Apple's PHPicker code.
// 2. The "Cancel" button did not work — users were forced to select an image.
//
// REPLACED BY: SwiftUI's native PhotosPicker (iOS 16+).
// See ImageMoveAndScaleSheet.swift for the PhotosPicker integration.

// public struct SystemPHPicker: UIViewControllerRepresentable {
//     ...entire struct...
// }
```

### 6c. `ImageMoveAndScaleSheet.swift` — integrate `PhotosPicker`

Add `import PhotosUI` at the top of the file.

Add a new `@State` property for the PhotosPicker selection:

```swift
// PhotosPicker binds to this item. When the user selects a photo,
// this property is set, triggering the .onChange handler to load the image.
@State private var selectedPhoto: PhotosPickerItem?
```

Comment out the old `isShowingImagePicker` state and the `.sheet` modifier:

```swift
// COMMENTED OUT — this boolean drove the old .sheet presentation of
// SystemUIImagePicker / SystemPHPicker. PhotosPicker handles its own
// presentation internally, so no manual sheet management is needed.
// @State private var isShowingImagePicker = false
```

Comment out the old `.sheet` block (lines 176–191):

```swift
// COMMENTED OUT — the .sheet that presented SystemUIImagePicker.
// PhotosPicker replaces this entire presentation flow.
// .sheet(isPresented: $isShowingImagePicker, onDismiss: loadImage) {
//     SystemUIImagePicker(image: self.$inputImage)
//         .accentColor(Color.systemRed)
// }
```

Replace the `openSystemPickerButton` (lines 216–229) with a `PhotosPicker`:

```swift
// COMMENTED OUT — the old button opened a .sheet containing a UIKit picker.
// private var openSystemPickerButton: some View {
//     ZStack {
//         Image(systemName: "circle.fill")
//             .font(.custom("system", size: 45))
//             .opacity(0.9)
//             .foregroundColor( ( displayedImage == nil ) ? .systemGreen : .white)
//         Image(systemName: "photo.on.rectangle")
//             .imageScale(.medium)
//             .foregroundColor(.black)
//             .onTapGesture {
//                 isShowingImagePicker = true
//             }
//     }
// }

// REPLACEMENT — native SwiftUI PhotosPicker. It renders as a label
// (the same circular icon as before) and handles its own presentation.
// When the user selects a photo, `selectedPhoto` is updated, which
// triggers the .onChange modifier to load the UIImage asynchronously.
private var openSystemPickerButton: some View {
    PhotosPicker(selection: $selectedPhoto,
                 matching: .images,
                 photoLibrary: .shared()) {
        ZStack {
            Image(systemName: "circle.fill")
                .font(.custom("system", size: 45))
                .opacity(0.9)
                .foregroundColor(displayedImage == nil ? .green : .white)
            Image(systemName: "photo.on.rectangle")
                .imageScale(.medium)
                .foregroundColor(.black)
        }
    }
}
```

Add an `.onChange` modifier to handle the selected photo item:

```swift
// When the user selects a new photo via PhotosPicker, load it
// asynchronously using the Transferable protocol. This replaces
// the old onDismiss → loadImage() callback chain.
.onChange(of: selectedPhoto) { _, newItem in
    guard let newItem else { return }
    newItem.loadTransferable(type: Data.self) { result in
        switch result {
        case .success(let data):
            if let data, let uiImage = UIImage(data: data) {
                // Update on main actor since we're modifying @State.
                DispatchQueue.main.async {
                    self.inputImage = uiImage
                    self.loadImage()
                }
            }
        case .failure(let error):
            print("PhotosPicker error: \(error.localizedDescription)")
        }
    }
}
```

### Verification
- `SystemImagePicker.swift` and `SystemPHPicker.swift` are fully commented
  out — no symbols exported.
- `ImageMoveAndScaleSheet.swift` uses `PhotosPicker` directly.
- Build succeeds. Photo selection works end-to-end.

---

## Step 7 — Replace `UIScreen.main.bounds` with `GeometryReader`

**Files modified:**
1. `Sources/ImageMoveAndScaleSheet.swift`
2. `Sources/ImageMoveAndScaleSheet+Extensions.swift`

**Why:** `UIScreen.main` was deprecated in iOS 16. It does not account for
iPad Split View, Stage Manager, or Slide Over. All sizing must be relative
to the actual container, not the physical screen.

### 7a. Add a `containerSize` state to `ImageMoveAndScaleSheet.swift`

```swift
// Stores the actual size of the view's container, obtained from
// GeometryReader. This replaces all uses of UIScreen.main.bounds
// throughout this file and its extensions, ensuring correct behavior
// in iPad Split View, Stage Manager, and Slide Over.
@State var containerSize: CGSize = .zero
```

### 7b. Wrap the body's ZStack in a `GeometryReader`

```swift
var body: some View {
    // GeometryReader provides the actual container dimensions,
    // replacing the deprecated UIScreen.main.bounds.
    GeometryReader { geometry in
        // ... existing ZStack content moves inside here ...
    }
    // Capture the container size once and whenever it changes
    // (e.g. device rotation, Split View resize).
    .onGeometryChange(for: CGSize.self) { proxy in
        proxy.size
    } action: { newSize in
        containerSize = newSize
    }
}
```

### 7c. Comment out every `UIScreen.main.bounds` usage

Each occurrence is replaced with the equivalent expression using
`containerSize`. Below is the mapping:

| Location | Old expression | New expression | Reason |
|----------|---------------|----------------|--------|
| Line 66 (`defaultImageSide`) | `UIScreen.main.bounds.width` | Compute inside body using `containerSize.width` | Constant `let` can't reference `@State`; move to computed property or calculate inline |
| Line 87 (`.frame`) | `UIScreen.main.bounds.width/height` | `containerSize.width/height` | |
| Line 201 (mask rect) | `UIScreen.main.bounds.width/height` | `containerSize.width/height` | |
| Line 202 (mask insetRect) | `UIScreen.main.bounds.width/height` | `containerSize.width/height` | |
| Extensions:52 (`getAspect`) | `UIScreen.main.bounds.width/height` | `containerSize.width/height` | |
| Extensions:63–68 (`resetImageOriginAndScale`) | `UIScreen.main.bounds.width/height` | `containerSize.width/height` | |
| Extensions:83 (`repositionImage`) | `UIScreen.main.bounds.width/height` | `containerSize.width/height` | |
| Extensions:90, 98 | `UIScreen.main.bounds.height/width` | `containerSize.height/width` | |
| Extensions:179 (`composeImageAttributes`) | `UIScreen.main.bounds.width/height` | `containerSize.width/height` | |

The `defaultImageSide` let-constant (line 66) currently uses
`UIScreen.main.bounds.width` at declaration time. Since it needs the
container size which is only known at render time, convert it to a
computed property:

```swift
// COMMENTED OUT — computed from UIScreen.main.bounds.width at init time.
// This produced a fixed value that was wrong on iPads and in Split View.
// let defaultImageSide = (UIScreen.main.bounds.width - (30))
//     * CGFloat(2).squareRoot() / 2

// REPLACEMENT — computed from the actual container width, recalculated
// whenever the container resizes.
var defaultImageSide: CGFloat {
    (containerSize.width - (inset * 2)) * CGFloat(2).squareRoot() / 2
}
```

The `HoleShapeMask()` function (lines 200–206) takes no parameters and
reads `UIScreen.main.bounds` directly. Refactor it to accept a size:

```swift
// COMMENTED OUT — read UIScreen.main.bounds directly.
// func HoleShapeMask() -> Path {
//     let rect = CGRect(x: 0, y: 0,
//         width: UIScreen.main.bounds.width,
//         height: UIScreen.main.bounds.height)
//     ...
// }

// REPLACEMENT — accepts the container size as a parameter so the mask
// is always correctly sized for the actual available space.
func HoleShapeMask(in size: CGSize) -> Path {
    let rect = CGRect(origin: .zero, size: size)
    let insetRect = CGRect(
        x: inset,
        y: inset,
        width: size.width - (inset * 2),
        height: size.height - (inset * 2)
    )
    var shape = Rectangle().path(in: rect)
    shape.addPath(Circle().path(in: insetRect))
    return shape
}
```

Update the call site:

```swift
Rectangle()
    .fill(Color.black).opacity(0.55)
    // COMMENTED OUT — old mask used UIScreen size directly.
    // .mask(HoleShapeMask().fill(style: FillStyle(eoFill: true)))
    // REPLACEMENT — pass actual container size.
    .mask(HoleShapeMask(in: containerSize).fill(style: FillStyle(eoFill: true)))
```

### Verification
- All `UIScreen.main.bounds` references are commented out and replaced.
- Build succeeds. The view now sizes correctly in all window configurations.

---

## Step 8 — Fix `ImageMoveAndScaleSheet+Extensions.swift`

**File:** `Sources/ImageMoveAndScaleSheet+Extensions.swift`

**Why:** This file contains the core positioning and cropping logic that
ties the UI gestures to the final crop output. It has force-unwraps,
debug prints, and (after Step 7) now uses `containerSize` instead of
`UIScreen.main.bounds`.

### 8a. Update `getAspect()` to use `containerSize`

```swift
// COMMENTED OUT — read UIScreen.main.bounds directly.
// private func getAspect() -> CGFloat {
//     let screenAspectRatio = UIScreen.main.bounds.width
//         / UIScreen.main.bounds.height
//     return screenAspectRatio
// }

// REPLACEMENT — uses containerSize captured by GeometryReader in the
// parent view. This correctly reflects the available space, not the
// physical screen.
private func getAspect() -> CGFloat {
    guard containerSize.height > 0 else { return 1.0 }
    return containerSize.width / containerSize.height
}
```

### 8b. Update `resetImageOriginAndScale()`

Replace all `UIScreen.main.bounds.width/height` with `containerSize.width/height`.

### 8c. Update `repositionImage()`

Replace all `UIScreen.main.bounds.width/height` with
`containerSize.width/height`.

Comment out all `print()` debug statements:

```swift
// COMMENTED OUT — debug print statements should not ship in a library.
// They produce console noise for consumers and expose internal state.
// print("reposition")
// print("1. newPosition.height > verticalOffset")
// print("2. newPosition.height < ( verticalOffset * -1)")
// print("else: H")
// print("3. newPosition.width > horizontalOffset")
// print("4. newPosition.width < ( horizontalOffset * -1)")
// print("else: W")
```

### 8d. Fix `composeImageAttributes()` — remove force-unwraps, add bounds checking

```swift
func composeImageAttributes() {

    // COMMENTED OUT — force-unwrap on inputImage could crash if the user
    // taps "Use photo" before selecting an image (edge case, but possible).
    // let scale = (inputImage?.size.width)! / displayW
    // ...
    // let tempUIImage: UIImage = croppedImage(from: inputImage!, ...)

    // REPLACEMENT — guard-let safely unwraps inputImage. If it is nil,
    // we bail out silently rather than crashing.
    guard let inputImage = inputImage else { return }
    guard displayW > 0 else { return }

    let scale = inputImage.size.width / displayW

    // Use containerSize (from GeometryReader) instead of UIScreen.main.bounds
    // for the origin adjustment. This ensures consistent crop results
    // regardless of screen size or multi-window configuration.
    let originAdjustment = min(containerSize.width, containerSize.height)
    let diameter = (originAdjustment - inset * 2) * scale

    let xPos = (((displayW - originAdjustment) / 2) + inset
                + (currentPosition.width * -1)) * scale
    let yPos = (((displayH - originAdjustment) / 2) + inset
                + (currentPosition.height * -1)) * scale

    // Clamp the crop rect to the image bounds to prevent cropping
    // outside the image's pixel area (which would produce black/
    // transparent pixels or a crash).
    let clampedX = max(0, min(xPos, inputImage.size.width - diameter))
    let clampedY = max(0, min(yPos, inputImage.size.height - diameter))
    let clampedDiameter = min(diameter,
        min(inputImage.size.width - clampedX,
            inputImage.size.height - clampedY))

    let cropRect = CGRect(x: clampedX, y: clampedY,
                          width: clampedDiameter, height: clampedDiameter)

    let tempUIImage = croppedImage(from: inputImage, croppedTo: cropRect)

    imageAttributes.image = Image(uiImage: tempUIImage)
    imageAttributes.originalImage = inputImage
    imageAttributes.croppedImage = tempUIImage
    imageAttributes.scale = zoomAmount
    imageAttributes.xWidth = currentPosition.width
    imageAttributes.yHeight = currentPosition.height
}
```

### Verification
- No force-unwraps remain.
- No `UIScreen.main.bounds` remains.
- No `print()` statements remain.
- Crop rect is always within image bounds.

---

## Step 9 — Update remaining deprecations in `ImageMoveAndScaleSheet.swift`

**File:** `Sources/ImageMoveAndScaleSheet.swift`

### 9a. Replace `presentationMode` with `dismiss`

```swift
// COMMENTED OUT — @Environment(\.presentationMode) was deprecated in iOS 15.
// Calling presentationMode.wrappedValue.dismiss() is verbose and indirect.
// @Environment(\.presentationMode) var presentationMode

// REPLACEMENT — @Environment(\.dismiss) provides a direct callable action.
// Usage: dismiss() instead of presentationMode.wrappedValue.dismiss()
@Environment(\.dismiss) var dismiss
```

Update all three call sites:

```swift
// Cancel button (line 212):
// COMMENTED OUT: presentationMode.wrappedValue.dismiss()
dismiss()

// Save button (line 235):
// COMMENTED OUT: presentationMode.wrappedValue.dismiss()
dismiss()
```

### 9b. Replace `.edgesIgnoringSafeArea(.all)`

```swift
// COMMENTED OUT — .edgesIgnoringSafeArea() was deprecated in iOS 14.
// .edgesIgnoringSafeArea(.all)

// REPLACEMENT — .ignoresSafeArea() is the modern equivalent.
.ignoresSafeArea()
```

### 9c. Remove duplicate localized strings

The same four `NSLocalizedString` calls exist in both
`ImageMoveAndScaleSheet.swift` (lines 70–73) and the `ViewModel`
(lines 25–28). Comment out the ones in the view, keep the ViewModel's:

```swift
// COMMENTED OUT — duplicate of the localized strings already defined in
// ViewModel. The view should read these from viewModel.moveAndScale, etc.
// let moveAndScale = NSLocalizedString(...)
// let selectPhoto = NSLocalizedString(...)
// let cancelSheet = NSLocalizedString(...)
// let usePhoto = NSLocalizedString(...)
```

Update the button labels and text to read from `viewModel` (most already do).

### Verification
- No deprecated `presentationMode` or `edgesIgnoringSafeArea` remains.
- Build succeeds.

---

## Step 10 — Update `ImagePane.swift`

**File:** `Sources/ImagePane.swift`

### 10a. Remove unused `inputImage` state

```swift
// COMMENTED OUT — this @State property was declared but never written to
// or read from anywhere in ImagePane. The actual input image flows through
// imageAttributes.originalImage.
// @State private var inputImage: UIImage?
```

### 10b. Simplify the initializers

With `@Observable`, the initializers no longer need the
`ObservedObject(initialValue:)` wrapper (already done in Step 5e). Verify
all four public initializers use plain assignment.

### Verification
- Build succeeds. ImagePane displays and triggers the photo selection sheet
  as before.

---

## Step 11 — Modernize preview providers

**Files:**
1. `Sources/ImageMoveAndScaleSheet.swift` (lines 243–249)
2. `Sources/ImagePane.swift` (lines 108–133)

**Why:** `PreviewProvider` structs were replaced by the `#Preview` macro in
Swift 5.9 / Xcode 15. The macro is more concise and supports multiple
named previews.

### 11a. `ImageMoveAndScaleSheet.swift`

```swift
// COMMENTED OUT — PreviewProvider is the legacy preview mechanism.
// struct ImageMoveAndScaleSheet_Previews: PreviewProvider {
//     static var previews: some View {
//         ImageMoveAndScaleSheet(
//             viewModel: ImageMoveAndScaleSheet.ViewModel(),
//             imageAttributes: ImageAttributes(withSFSymbol: "photo.circle.fill")
//         )
//     }
// }

// REPLACEMENT — #Preview macro. Concise, supports naming, and is the
// standard in Xcode 15+ / Swift 5.9+.
#Preview("Move and Scale Sheet") {
    ImageMoveAndScaleSheet(
        viewModel: ImageMoveAndScaleSheet.ViewModel(),
        imageAttributes: ImageAttributes(withSFSymbol: "photo.circle.fill")
    )
}
```

### 11b. `ImagePane.swift`

```swift
// COMMENTED OUT — legacy PreviewProvider.
// struct ImagePane_Previews: PreviewProvider { ... }

// REPLACEMENT — #Preview macros, one per variant.
#Preview("Default") {
    let placeholder = ImageAttributes(withSFSymbol: "photo.circle")
    ImagePane(image: placeholder, isEditMode: .constant(true))
        .frame(width: 150, height: 150, alignment: .center)
        .foregroundColor(.pink.opacity(0.25))
        .padding()
        .background(.white)
}

#Preview("Palette") {
    let placeholder = ImageAttributes(withSFSymbol: "photo.circle")
    ImagePane(image: placeholder, isEditMode: .constant(false),
              renderingMode: .palette, colors: [.blue, .white])
        .frame(width: 150, height: 150, alignment: .center)
        .padding()
        .background(.gray)
}

#Preview("Gradient") {
    let placeholder = ImageAttributes(withSFSymbol: "photo.circle")
    ImagePane(image: placeholder, isEditMode: .constant(true),
              renderingMode: .monochrome,
              linearGradient: LinearGradient(
                  colors: [.yellow, .red],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing))
        .frame(width: 150, height: 150, alignment: .center)
        .padding()
        .background(.black)
}
```

### Verification
- Previews render in Xcode. Build succeeds.

---

## Step 12 — Clean up `ViewModifiers.swift`

**File:** `Sources/ViewModifiers.swift`

**Why:** This file is fine functionally but could benefit from a brief
doc comment explaining its purpose.

### Changes

Add a header comment:

```swift
/// A ViewModifier that applies foreground styling based on the number
/// of colors provided. Supports:
/// - Single color
/// - Two-color hierarchical rendering
/// - Three-color hierarchical rendering
/// - Linear gradient rendering
///
/// Used by ImagePane to style SF Symbol placeholder images with the
/// rendering mode chosen by the consumer.
```

No structural changes needed — this file uses no deprecated APIs.

---

## Step 13 — Clean up `Color+Extensions.swift` (finish Step 3)

**File:** `Sources/Color+Extensions.swift`

Now that Step 9 has replaced all `Color.systemRed` usage in
`ImageMoveAndScaleSheet.swift` (the picker uses `.green` directly now),
complete the commenting-out of `systemRed` that was deferred in Step 3:

```swift
// COMMENTED OUT — SwiftUI provides Color.red as a direct equivalent.
// static var systemRed: Color {
//     return Color(UIColor.systemRed)
// }
```

Also comment out `systemGreen` if no longer used (check after Step 6
replaces the picker button):

```swift
// COMMENTED OUT — SwiftUI provides Color.green as a direct equivalent.
// The PhotosPicker button now uses .green directly.
// static var systemGreen: Color {
//     return Color(UIColor.systemGreen)
// }
```

### Verification
- `grep -r "Color.systemRed\|Color.systemGreen\|\.systemRed\|\.systemGreen"` returns
  no results in non-commented code.
- Build succeeds.

---

## Step 14 — Final verification pass

**All files.**

### Checklist

| Check | How to verify |
|-------|---------------|
| No force-unwraps in crop pipeline | Search for `!` in ImageManipulation.swift and Extensions.swift |
| No `UIScreen.main` anywhere | `grep -r "UIScreen.main"` returns only commented-out lines |
| No `presentationMode` anywhere | `grep -r "presentationMode"` returns only commented-out lines |
| No `@Published` anywhere | `grep -r "@Published"` returns only commented-out lines |
| No `ObservableObject` anywhere | `grep -r "ObservableObject"` returns only commented-out lines |
| No `@StateObject` anywhere | `grep -r "@StateObject"` returns only commented-out lines |
| No `@ObservedObject` anywhere | `grep -r "@ObservedObject"` returns only commented-out lines |
| No `UIGraphicsBeginImageContext` | `grep -r "UIGraphicsBeginImageContext"` returns only commented-out lines |
| No `edgesIgnoringSafeArea` | `grep -r "edgesIgnoringSafeArea"` returns only commented-out lines |
| No `PreviewProvider` | `grep -r "PreviewProvider"` returns only commented-out lines |
| No debug `print()` in library | `grep -rn "print("` returns only commented-out lines |
| No `UIImagePickerController` | `grep -r "UIImagePickerController"` returns only commented-out lines |
| No `PHPickerViewController` | `grep -r "PHPickerViewController"` returns only commented-out lines |
| Package.swift targets iOS 17 | Visual inspection |
| Package.swift tools version 5.9+ | Visual inspection |
| All new code has explanatory comments | Visual inspection of each file |

### Run the build

```
swift build
```

Must complete with zero errors and zero warnings (other than any pre-existing
warnings unrelated to our changes).

---

## Execution Order Summary

```
Step  1: Package.swift ..................... foundation for all subsequent steps
Step  2: ImageManipulation.swift ........... standalone leaf, fixes crop quality
Step  3: Color+Extensions.swift ............ standalone leaf, partial cleanup
Step  4: Image+Extensions.swift ............ standalone leaf, remove dead code
Step  5: @Observable migration ............. coordinated across 5 files
         5a: ImageAttributes.swift
         5b: DeviceOrientation.swift
         5c: ViewModel.swift
         5d: ImageMoveAndScaleSheet.swift (property wrappers only)
         5e: ImagePane.swift (property wrapper only)
Step  6: PhotosPicker replacement .......... coordinated across 3 files
         6a: SystemImagePicker.swift (comment out)
         6b: SystemPHPicker.swift (comment out)
         6c: ImageMoveAndScaleSheet.swift (add PhotosPicker)
Step  7: GeometryReader migration .......... coordinated across 2 files
         7a–c: ImageMoveAndScaleSheet.swift
Step  8: Extensions fixes .................. ImageMoveAndScaleSheet+Extensions.swift
         8a: getAspect()
         8b: resetImageOriginAndScale()
         8c: repositionImage()
         8d: composeImageAttributes()
Step  9: Remaining deprecations ............ ImageMoveAndScaleSheet.swift
         9a: presentationMode → dismiss
         9b: edgesIgnoringSafeArea → ignoresSafeArea
         9c: duplicate localized strings
Step 10: ImagePane cleanup ................. ImagePane.swift
Step 11: Preview modernization ............. 2 files
Step 12: ViewModifiers docs ................ ViewModifiers.swift
Step 13: Color+Extensions finish ........... Color+Extensions.swift
Step 14: Final verification ................ all files, build, grep checks
```

Each step is designed so that `swift build` succeeds after it completes.
Steps within a coordinated group (5a–5e, 6a–6c, 7a–7c) must all be applied
together before building.
