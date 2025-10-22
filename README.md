# ToastView 2.0 🍞

Easily display toast messages with optional icons, progress indicators, and stunning Liquid Glass effects in your iOS and tvOS apps.

<p align="center">
  <img src="https://github.com/paoloandrea/ToastView/blob/main/Assets/toastview_v1.gif?raw=true" alt="Screenshot of ToastView" width="250px" />
</p>


## Features

- 🌟 Display simple toast messages or toasts with icons.
- 🔄 Optional progress indicator for toasts that represent a loading state.
- ✨ **Liquid Glass effect** on iOS 26+ / tvOS 26+ with automatic fallback to blur on older versions.
- 🌓 Automatic dark mode and light mode support.
- 🌌 Optional blurred/glass background to overlay entire application.
- 📱 Full support for iOS 13+ and tvOS 13+.
- 📍 7 customizable toast display positions (topLeft, top, topRight, center, bottomLeft, bottom, bottomRight).
- 🔤 Multi-line message support.
- 🎯 Multiple toasts support with smart positioning.
- 📊 **Smart TabBar detection**: Automatically positions bottom toasts above the UITabBarController when present (16px spacing).

## Requirements

- iOS 13.0+ / tvOS 13.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add ToastView to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/paoloandrea/ToastView.git", from: "2.0.0")
]
```

### Manual

1. Download the `ToastManager.swift` and `ToastView.swift` files from this repository.
2. Add them to your Xcode project.

## Usage

1. **Basic Toast**
Since `ToastManager` is a singleton, you do not instantiate it directly. Instead, you access the shared instance as follows:

```swift
let toastManager = ToastManager.shared
```

```swift
toastManager.showToast(
    message: "Your message here",
    image: UIImage(named: "your_image_name"),
    isProgress: false,
    position: .center,
    duration: 2.0,
    in: yourView,
    withBackground: true)
```

2. **Toast with Icon**

```swift
    let image = UIImage(systemName: "star.fill")
    toastManager.showToast(message: "Starred", image: image, position: .top)
```

3. **Toast with Progress Indicator**

```swift
    toastManager.showToast(message: "Loading...", isProgress: true, position: .bottom)
```

4. **Toast with Blurred Background Overlay**

```swift
    toastManager.showToast(message: "Blurred Background", position: .center, withBackground: true)
```

5. **Dismiss Toast Manually**

```swift
    toastManager.cancelCurrentToast()
```

6. **Dismiss Toast After a Delay**

```swift
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        toastManager.cancelCurrentToast()
    }
```

## Advanced Features

### Update Toast Message

Update the message of the current toast without creating a new one:

```swift
toastManager.message = "Updated message"
```

### Multiple Toasts

Enable multiple toasts to stack vertically:

```swift
toastManager.allowMultipleToasts = true
toastManager.showToast(message: "First toast", position: .top)
toastManager.showToast(message: "Second toast", position: .top)
```

### Toast Positions

Available positions: `.topLeft`, `.top`, `.topRight`, `.center`, `.bottomLeft`, `.bottom`, `.bottomRight`

### Smart TabBar Detection

When displaying toasts at bottom positions (`.bottom`, `.bottomLeft`, `.bottomRight`), ToastView automatically detects if a `UITabBarController` is present in the view hierarchy. If a visible tab bar is found, the toast will be positioned **16px above the tab bar** instead of at the bottom safe area, ensuring the toast is always visible and not obscured by the tab bar.

This feature works automatically without any configuration:

```swift
// In a view controller within a UITabBarController
toastManager.showToast(message: "Toast positioned above tab bar", position: .bottom)
```

**Note**: The detection only works when:
- A `UITabBarController` exists in the view hierarchy
- The tab bar is visible (not hidden)

## Visual Effects

### Liquid Glass Effect (iOS 26+ / tvOS 26+)

On iOS 26 and tvOS 26 or later, ToastView automatically uses the stunning **Liquid Glass effect** (`UIGlassEffect`) for a modern, translucent appearance. On older versions, it gracefully falls back to `UIBlurEffect`.

### Dark Mode Support

ToastView automatically adapts to the system's light/dark mode appearance using semantic colors and adaptive materials.

## Configuration Options

- **allowMultipleToasts**: Set to `true` to allow showing multiple toasts at once (default: `false`).
- **message**: Update the current toast message without recreating the toast.
- **duration**: Set to `0` for indefinite display, or specify seconds for auto-dismiss.
- **withBackground**: Add a blurred/glass overlay behind the toast.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

MIT License - see [LICENSE](https://choosealicense.com/licenses/mit/) for details.
