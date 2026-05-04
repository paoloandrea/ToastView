//
//  ToastView.swift
//  ToastView
//
//  Created by Paolo Rossignoli on 14/09/23.
//
import UIKit

/// An enum representing the possible positions for a toast on the screen.
public enum ToastPosition {
    case topLeft, top, topRight, center, bottomLeft, bottom, bottomRight
    case bottomLeftAboveTabBar, bottomAboveTabBar, bottomRightAboveTabBar
}

/// A `ToastView` is a custom UIView used to display non-intrusive messages for a short duration.
///
/// - Note:
///   Toasts can be accompanied by icons or a loading spinner.
///   They can be displayed at various positions on the screen.
public class ToastView: UIView {

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let toastLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
#if os(iOS)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
#elseif os(tvOS)
        label.font = .systemFont(ofSize: 29)
#endif
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .label
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var visualEffectView: UIVisualEffectView!
    private var backgroundView: UIView?
    private var duration: TimeInterval = 0.0

    // MARK: - Layout constants

#if os(iOS)
    private var labelPadding: CGFloat = 16.0
    private let imageSize: CGFloat = 25.0
    private let toastHeight: CGFloat = 37
    private let toastWidth: CGFloat = 300
#elseif os(tvOS)
    private var labelPadding: CGFloat = 20.0
    private let imageSize: CGFloat = 44.0
    private let toastHeight: CGFloat = 60
    private let toastWidth: CGFloat = 800
#endif
    private let toastPadding: CGFloat = 8.0

    // MARK: - Public state

    public var position: ToastPosition?
    public var containerView: UIView?

    /// `true` while the toast is attached to a superview.
    public var isShowing: Bool { superview != nil }

    // MARK: - Init

    init() {
        super.init(frame: .zero)
        setupHierarchy()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHierarchy() {
        backgroundColor = .clear

        visualEffectView = Self.makeGlassEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)

        // Mask the glass surface itself, not the host view, so Liquid Glass
        // renders correctly within the rounded shape on iOS/tvOS 26+.
        visualEffectView.layer.cornerRadius = (toastHeight + toastPadding) / 2
        visualEffectView.layer.cornerCurve = .continuous
        visualEffectView.layer.masksToBounds = true

        if #available(iOS 26.0, tvOS 26.0, *) {
            // Liquid Glass renders content directly in `contentView`.
            visualEffectView.contentView.addSubview(stackView)
            stackView.addArrangedSubview(toastLabel)
        } else if let blurEffect = visualEffectView.effect as? UIBlurEffect {
            // Pre-iOS 26: pair the blur with vibrancy for proper text rendering.
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
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
        } else {
            visualEffectView.contentView.addSubview(stackView)
            stackView.addArrangedSubview(toastLabel)
        }

        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: toastHeight - toastPadding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -labelPadding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: toastPadding),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -toastPadding),
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: toastWidth),
        ])
    }

    /// Returns a `UIVisualEffectView` configured with Liquid Glass on iOS/tvOS 26+,
    /// or a blur effect on older versions. tvOS doesn't expose
    /// `UIBlurEffect.Style.systemMaterial`, so we fall back to `.regular` there.
    private static func makeGlassEffectView() -> UIVisualEffectView {
        if #available(iOS 26.0, tvOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .regular)
            return UIVisualEffectView(effect: glassEffect)
        }
#if os(iOS)
        let blurEffect = UIBlurEffect(style: .systemMaterial)
#elseif os(tvOS)
        let blurEffect = UIBlurEffect(style: .regular)
#endif
        return UIVisualEffectView(effect: blurEffect)
    }

    // MARK: - Public API

    func updateMessage(newMessage: String) {
        toastLabel.text = newMessage
    }

    /// Displays the toast on the screen.
    func prepareToShow(message: String,
                       image: UIImage? = nil,
                       isProgress: Bool = false,
                       position: ToastPosition = .center,
                       duration: TimeInterval = 0,
                       in view: UIView? = nil,
                       withBackground: Bool = false,
                       completion: (() -> Void)? = nil) {

        self.duration = duration
        self.toastLabel.text = message
        self.position = position

        if let image = image {
            self.iconImageView.image = image.withRenderingMode(.alwaysTemplate)
            self.iconImageView.tintColor = .label
            self.stackView.insertArrangedSubview(self.iconImageView, at: 0)
            NSLayoutConstraint.activate([
                self.iconImageView.widthAnchor.constraint(equalToConstant: self.imageSize),
                self.iconImageView.heightAnchor.constraint(equalToConstant: self.imageSize)
            ])
        } else if isProgress {
            self.stackView.insertArrangedSubview(self.activityIndicator, at: 0)
            NSLayoutConstraint.activate([
                self.activityIndicator.widthAnchor.constraint(equalToConstant: self.imageSize),
                self.activityIndicator.heightAnchor.constraint(equalToConstant: self.imageSize)
            ])
            self.activityIndicator.startAnimating()
        }

        let resolvedContainer = view ?? Self.resolvedKeyWindow()
        guard let containerView = resolvedContainer else { return }
        self.containerView = containerView

        // Optional dim/glass overlay.
        if withBackground {
            let background = UIView(frame: containerView.bounds)
            background.backgroundColor = UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.black.withAlphaComponent(0.6)
                case .light, .unspecified:
                    return UIColor.black.withAlphaComponent(0.4)
                @unknown default:
                    return UIColor.black.withAlphaComponent(0.6)
                }
            }
            background.isUserInteractionEnabled = true
            background.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            containerView.addSubview(background)

            let backgroundEffectView = Self.makeGlassEffectView()
            backgroundEffectView.frame = background.bounds
            backgroundEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            background.addSubview(backgroundEffectView)
            backgroundView = background
        }

        translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(self)

        let tabBarOffset = containerView.toast_tabBarOffset()
        let forcedTabBarOffset = tabBarOffset > 0 ? tabBarOffset : Self.fallbackTabBarOffset

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
        case .bottomLeftAboveTabBar:
            NSLayoutConstraint.activate([
                self.leadingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.leadingAnchor, constant: self.toastPadding),
                self.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -(self.toastPadding + forcedTabBarOffset)),
            ])
        case .bottomAboveTabBar:
            NSLayoutConstraint.activate([
                self.centerXAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.centerXAnchor),
                self.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -(self.toastPadding + forcedTabBarOffset)),
            ])
        case .bottomRightAboveTabBar:
            NSLayoutConstraint.activate([
                self.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -self.toastPadding),
                self.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -(self.toastPadding + forcedTabBarOffset)),
            ])
        }

        containerView.layoutIfNeeded()

        self.alpha = 0.0
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1.0
        }) { [weak self] _ in
            guard let self = self, duration > 0.0 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.dismiss(completion: completion)
            }
        }
    }

    /// Fades the toast out and removes it from the view hierarchy.
    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0.0
            self.backgroundView?.alpha = 0.0
        }) { [weak self] _ in
            guard let self = self else { return }
            self.removeFromSuperview()
            self.backgroundView?.removeFromSuperview()
            self.backgroundView = nil
            completion?()
        }
    }

    // MARK: - Helpers

    /// Standard iPhone tab bar height (49pt) + 16pt spacing. Used when no
    /// `UITabBarController` is present and the caller forced an "AboveTabBar"
    /// position. iOS 26's floating tab bar is auto-detected via the responder
    /// chain, so this fallback only applies when there's no controller at all.
    private static let fallbackTabBarOffset: CGFloat = 49 + 16

    /// Resolves the active key window using the modern `connectedScenes` API
    /// when available, falling back to the legacy `windows` array.
    static func resolvedKeyWindow() -> UIWindow? {
        if #available(iOS 15.0, tvOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
        }
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
}

// MARK: - Tab bar detection

extension UIView {
    /// Walks the responder chain looking for a visible `UITabBarController`
    /// and returns its tab bar height plus 16pt spacing, or 0 if none.
    func toast_tabBarOffset() -> CGFloat {
        var responder: UIResponder? = self
        while let current = responder {
            if let tabBarController = current as? UITabBarController,
               !tabBarController.tabBar.isHidden {
                return tabBarController.tabBar.frame.height + 16
            }
            responder = current.next
        }
        return 0
    }
}
