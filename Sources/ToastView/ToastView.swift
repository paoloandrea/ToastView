//
//  Toast.swift
//  IPTV_Components
//
//  Created by Paolo Rossignoli on 14/09/23.
//
import UIKit

/// An enum representing the possible positions for a toast on the screen.
public enum ToastPosition {
    case topLeft, top, topRight, center, bottomLeft, bottom, bottomRight
}

/// A `ToastView` is a custom UIView used to display non-intrusive messages for a short duration.
///
/// - Note:
///   Toasts can be accompanied by icons or a loading spinner.
///   They can be displayed at various positions on the screen.
public class ToastView: UIView {
    
    /// The internal stack view that organizes the toast's content.
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    /// The label displaying the toast's message.
    private let toastLabel: UILabel = {
        let label = UILabel()
        // UIVibrancyEffect will handle the color automatically
        label.textColor = .label
#if os(iOS)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
#elseif os(tvOS)
        label.font = .systemFont(ofSize: 29)
#endif
        //label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    /// An optional icon to accompany the toast's message.
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    /// A loading spinner, shown when the toast represents a loading or progress state.
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        // UIVibrancyEffect will handle the color automatically
        indicator.color = .label
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // Add to your ToastView class properties:
    private var backgroundView: UIView? = nil

    private var duration: TimeInterval = 0.0

    /// Creates a visual effect view with Liquid Glass on iOS 26+ or blur effect on older versions
    /// - Returns: A configured UIVisualEffectView
    private func createVisualEffectView() -> UIVisualEffectView {
        if #available(iOS 26.0, tvOS 26.0, *) {
            // Use Liquid Glass effect for iOS/tvOS 26+ (internally iOS 18+)
            let glassEffect = UIGlassEffect(style: .regular)
            return UIVisualEffectView(effect: glassEffect)
        } else {
            // Fallback to UIBlurEffect for older versions
            #if os(iOS)
            // Use systemMaterial on iOS to automatically adapt to light/dark mode
            let blurEffect = UIBlurEffect(style: .systemMaterial)
            #elseif os(tvOS)
            // Use regular blur on tvOS (systemMaterial not available)
            let blurEffect = UIBlurEffect(style: .regular)
            #endif
            return UIVisualEffectView(effect: blurEffect)
        }
    }
    
#if os(iOS)
    private var labelPadding: CGFloat = 16.0
    private let imageSize = 25.0
    private let toastHeight:CGFloat = 37
#elseif os(tvOS)
    private var labelPadding: CGFloat = 20.0
    private let imageSize = 44.0
    private let toastHeight:CGFloat = 60
#endif
    private let toastPadding = 8.0
    public var position:ToastPosition?
    public var containerView: UIView?
    var dismissHandler: (() -> Void)?

    // Indicates whether the ToastView is currently showing on the screen
    private var _isShowing: Bool = false
    public var isShowing: Bool {
        return _isShowing
    }

    /// Returns the tab bar height with additional spacing if a UITabBarController is present
    /// - Parameter containerView: The container view to search for a tab bar controller
    /// - Returns: The offset to apply (tab bar height + 16px) or 0 if no tab bar exists
    private func getTabBarOffset(for containerView: UIView) -> CGFloat {
        // Try to find the UITabBarController in the view hierarchy
        var responder: UIResponder? = containerView

        while responder != nil {
            if let tabBarController = responder as? UITabBarController,
               !tabBarController.tabBar.isHidden {
                // Tab bar exists and is visible, return its height + 16px spacing
                return tabBarController.tabBar.frame.height + 16
            }
            responder = responder?.next
        }

        // No tab bar controller found or tab bar is hidden
        return 0
    }
    
    private init() {
        super.init(frame: .zero)

        // Create the visual effect view with version-appropriate effect
        let visualEffectView = createVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)

        backgroundColor = .clear

        // Add vibrancy effect for proper text rendering
        if #available(iOS 26.0, tvOS 26.0, *) {
            // iOS 26+ Liquid Glass renders content directly in contentView
            visualEffectView.contentView.addSubview(stackView)
            stackView.addArrangedSubview(toastLabel)
        } else {
            // Older versions use UIVibrancyEffect with blur for proper text rendering
            let vibrancyEffect = UIVibrancyEffect(blurEffect: visualEffectView.effect as! UIBlurEffect)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyView.translatesAutoresizingMaskIntoConstraints = false
            visualEffectView.contentView.addSubview(vibrancyView)

            vibrancyView.contentView.addSubview(stackView)
            stackView.addArrangedSubview(toastLabel)

            NSLayoutConstraint.activate([
                vibrancyView.leadingAnchor.constraint(equalTo: visualEffectView.contentView.leadingAnchor),
                vibrancyView.trailingAnchor.constraint(equalTo: visualEffectView.contentView.trailingAnchor),
                vibrancyView.topAnchor.constraint(equalTo: visualEffectView.contentView.topAnchor),
                vibrancyView.bottomAnchor.constraint(equalTo: visualEffectView.contentView.bottomAnchor)
            ])
        }
#if os(iOS)
        let widthToast:CGFloat = 300
#elseif os(tvOS)
        let widthToast:CGFloat = 800
#endif
        
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: toastHeight-toastPadding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -labelPadding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: toastPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -toastPadding),
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: widthToast),
        ])
        
        layer.cornerRadius = (toastHeight+toastPadding) / 2
        layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Nella classe ToastView
    func updateMessage(newMessage: String) {
        // Aggiorna il messaggio visualizzato nel toast
        self.toastLabel.text = newMessage
    }
    
    /// Displays a toast message on the screen.
    ///
    /// - Parameters:
    ///   - message: The message to be displayed.
    ///   - image: An optional image icon to accompany the message.
    ///   - isProgress: Determines if a loading spinner should be displayed. Defaults to `false`.
    ///   - position: The position on the screen where the toast should appear. Defaults to `.center`.
    ///   - duration: The duration for which the toast should be displayed. Defaults to `0` (indefinitely).
    ///   - view: The view on which the toast should be displayed. Defaults to the key window.
    ///
    /// - Note:
    ///   If both `image` and `isProgress` are provided, the image takes precedence and the loading spinner is not shown.
    func prepareToShow(message: String, image: UIImage? = nil, isProgress: Bool = false, position: ToastPosition = .center, duration: TimeInterval = 0, in view: UIView? = nil, withBackground: Bool = false, completion: (() -> Void)? = nil) {
       
        self.duration = duration
        self.toastLabel.text = message
        self._isShowing = true  // Set the visibility to true when showing the toast
        self.position = position
        
        if let image = image {
            // UIVibrancyEffect will handle the tinting automatically
            self.iconImageView.image = image.withRenderingMode(.alwaysTemplate)
            self.iconImageView.tintColor = .label
            self.stackView.insertArrangedSubview(self.iconImageView, at: 0)
            self.iconImageView.widthAnchor.constraint(equalToConstant: self.imageSize).isActive = true
            self.iconImageView.heightAnchor.constraint(equalToConstant: self.imageSize).isActive = true
        } else if isProgress {
            self.stackView.insertArrangedSubview(self.activityIndicator, at: 0)
            self.activityIndicator.widthAnchor.constraint(equalToConstant: self.activityIndicator.frame.width).isActive = true
            self.activityIndicator.heightAnchor.constraint(equalToConstant: self.activityIndicator.frame.height).isActive = true
            self.activityIndicator.startAnimating()
        }
        
        
        if let view = view {
            self.containerView = view
        } else {
            // Get the key window using the appropriate API based on iOS version
            if #available(iOS 15.0, tvOS 15.0, *) {
                // Use UIWindowScene for iOS/tvOS 15+
                self.containerView = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first(where: { $0.isKeyWindow })
            } else {
                // Fallback for iOS/tvOS 13-14
                self.containerView = UIApplication.shared.windows.first(where: { $0.isKeyWindow })
            }

            if self.containerView == nil {
                return
            }
        }
        
        guard let containerView = containerView else {
            return
        }
        containerView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false

        // Calculate tab bar offset for bottom positions
        let tabBarOffset = getTabBarOffset(for: containerView)

        switch position {
        case .topLeft:
            NSLayoutConstraint.activate([
                self.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: self.toastPadding),
                self.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: self.toastPadding),
            ])
        case .top:
            NSLayoutConstraint.activate([
                self.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
                self.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: self.toastPadding),
            ])
        case .topRight:
            NSLayoutConstraint.activate([
                self.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -self.toastPadding),
                self.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: self.toastPadding),
            ])
        case .center:
            NSLayoutConstraint.activate([
                self.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
                self.centerYAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerYAnchor),
            ])
        case .bottomLeft:
            NSLayoutConstraint.activate([
                self.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: self.toastPadding),
                self.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -(self.toastPadding + tabBarOffset)),
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                self.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
                self.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -(self.toastPadding + tabBarOffset)),
            ])
        case .bottomRight:
            NSLayoutConstraint.activate([
                self.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -self.toastPadding),
                self.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -(self.toastPadding + tabBarOffset)),
            ])
        }
        
        if withBackground {
            let background = UIView(frame: containerView.bounds)
            // Use dynamic background color that adapts to light/dark mode
            let dynamicBackgroundColor = UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.black.withAlphaComponent(0.6)
                case .light, .unspecified:
                    return UIColor.black.withAlphaComponent(0.4)
                @unknown default:
                    return UIColor.black.withAlphaComponent(0.6)
                }
            }
            background.backgroundColor = dynamicBackgroundColor
            background.isUserInteractionEnabled = true // disable interactions
            containerView.addSubview(background)

            // Use version-appropriate visual effect for background
            let backgroundEffectView: UIVisualEffectView
            if #available(iOS 26.0, tvOS 26.0, *) {
                // Use Liquid Glass effect for iOS/tvOS 26+
                let glassEffect = UIGlassEffect(style: .regular)
                backgroundEffectView = UIVisualEffectView(effect: glassEffect)
            } else {
                // Fallback to UIBlurEffect for older versions
                #if os(iOS)
                // Use systemMaterial on iOS to automatically adapt to light/dark mode
                let blurEffect = UIBlurEffect(style: .systemMaterial)
                #elseif os(tvOS)
                // Use regular blur on tvOS (systemMaterial not available)
                let blurEffect = UIBlurEffect(style: .regular)
                #endif
                backgroundEffectView = UIVisualEffectView(effect: blurEffect)
            }

            backgroundEffectView.frame = background.bounds
            backgroundEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            background.addSubview(backgroundEffectView)

            backgroundView = background
        }
        
        containerView.addSubview(self)
        containerView.layoutIfNeeded()
        
        self.alpha = 0.0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1.0
        }) { _ in
            if duration > 0.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    self.dismiss(completion: completion)
                }
            }
        }
    }
   
    /// Dismisses the toast, fading it out of view.
    ///
    /// - Note:
    ///   This method is called automatically after the duration specified when showing the toast.
    ///   It can also be called manually if needed.
    func dismiss(completion: (() -> Void)? = nil) {
        // ... existing implementation ...
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0.0
            self.backgroundView?.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
            self.backgroundView?.removeFromSuperview()
            self.backgroundView = nil
            
            self._isShowing = false
            completion?()
        }
    }

}
