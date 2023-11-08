# ToastView 2.0 🍞

Easily display toast messages with optional icons, progress indicators, and blurred backgrounds in your iOS app.

<p align="center">
  <img src="https://github.com/paoloandrea/ToastView/blob/main/Assets/toastview_v1.gif?raw=true" alt="Screenshot of ToastView" width="250px" />
</p>


## Features

- 🌟 Display simple toast messages or toasts with icons.
- 🔄 Optional progress indicator for toasts that represent a loading state.
- 🌌 Optional dark blurred background to overlay entire application.
- 📱 Support for both iOS and tvOS.
- 📍 Customizable toast display positions.

## Installation

### Manual

1. Download the `ToastManager.swift` and `ToastView.swift` file from this repository.
2. Add it to your Xcode project.

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

## Customization

### Toast Duration

You can set the duration for which a toast should be displayed.

```swift
toastManager.showToast(message: "This will dismiss in 5 seconds", duration: 5.0)
```

### Toast Position
Position the toast wherever you want using the ToastPosition enum.

## Configuration Options

- **allowMultipleToasts**: Set to true to allow showing multiple toasts at once.
- **toastPadding**: The spacing between multiple toasts, if enabled.

This guide should provide you with the basic usage of the ToastManager class to manage toast notifications in your app.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
#### MIT
https://choosealicense.com/licenses/mit/
