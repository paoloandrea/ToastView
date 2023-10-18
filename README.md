# ToastView 🍞

Easily display toast messages with optional icons, progress indicators, and blurred backgrounds in your iOS app.

![Screenshot of ToastView](https://github.com/paoloandrea/ToastView/Assets/toastview_v1.gif)

## Features

- 🌟 Display simple toast messages or toasts with icons.
- 🔄 Optional progress indicator for toasts that represent a loading state.
- 🌌 Optional dark blurred background to overlay entire application.
- 📱 Support for both iOS and tvOS.
- 📍 Customizable toast display positions.

## Installation

### Manual

1. Download the `ToastView.swift` file from this repository.
2. Add it to your Xcode project.

## Usage

1. **Basic Toast**
    ```swift
    ToastView.show(message: "Hello World", position: .center)
    ```

2. **Toast with Icon**
    ```swift
    let image = UIImage(systemName: "star.fill")
    ToastView.show(message: "Starred", image: image, position: .top)
    ```

3. **Toast with Progress Indicator**
    ```swift
    ToastView.show(message: "Loading...", isProgress: true, position: .bottom)
    ```

4. **Toast with Blurred Background Overlay**
    ```swift
    ToastView.show(message: "Blurred Background", position: .center, withBackground: true)
    ```

5. **Dismiss Toast Manually**
    ```swift
    ToastView.dismiss()
    ```

6. **Dismiss Toast After a Delay**
    ```swift
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        ToastView.dismiss()
    }
    ```

## Customization

### Toast Duration

You can set the duration for which a toast should be displayed.

```swift
ToastView.show(message: "This will dismiss in 5 seconds", duration: 5.0)
    ```

Toast Position
Position the toast wherever you want using the ToastPosition enum.

##Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

License

MIT
https://choosealicense.com/licenses/mit/
