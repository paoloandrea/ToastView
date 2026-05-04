//
//  ToastManager.swift
//  ToastView
//
//  Created by Paolo Rossignoli on 05/11/23.
//

import UIKit

/// `ToastManager` is a singleton that coordinates toast display, queuing and
/// dismissal. Use `ToastManager.shared` rather than creating instances.
public final class ToastManager {

    public static let shared = ToastManager()
    private init() {}

    private var toastQueue = [ToastView]()

    /// `true` while at least one toast is on screen.
    public var isCurrentlyShowing: Bool { !toastQueue.isEmpty }

    /// When `false` (default), `showToast` is a no-op while another toast is
    /// already visible. When `true`, toasts stack vertically.
    public var allowMultipleToasts = false

    private let toastPadding: CGFloat = 4

    /// Updates the message on the current toast in place. With multiple toasts
    /// active, only the first toast in the queue is updated.
    public var message: String? {
        didSet { updateCurrentToastMessage() }
    }

    /// Shows a toast.
    /// - Parameters:
    ///   - message: The message displayed in the toast.
    ///   - image: Optional leading icon.
    ///   - isProgress: When `true` (and `image` is nil), shows a spinner.
    ///   - position: One of the `ToastPosition` cases.
    ///   - duration: Auto-dismiss after this interval. Pass `0` to keep it
    ///     visible until manually dismissed.
    ///   - view: Optional container. Defaults to the key window.
    ///   - withBackground: When `true`, dims and blurs the rest of the screen.
    public func showToast(message: String,
                          image: UIImage? = nil,
                          isProgress: Bool = false,
                          position: ToastPosition = .center,
                          duration: TimeInterval = 2.0,
                          in view: UIView? = nil,
                          withBackground: Bool = false) {

        if !allowMultipleToasts && isCurrentlyShowing { return }

        guard let containerView = view ?? ToastView.resolvedKeyWindow() else { return }

        let toast = ToastView()
        toast.prepareToShow(message: message,
                            image: image,
                            isProgress: isProgress,
                            position: position,
                            duration: duration,
                            in: containerView,
                            withBackground: withBackground)

        toastQueue.append(toast)
        updateToastPositions(in: containerView)
    }

    /// Recalculates stacked positions when `allowMultipleToasts` is `true`.
    private func updateToastPositions(in containerView: UIView) {
        guard allowMultipleToasts else { return }

        let tabBarOffset = containerView.toast_tabBarOffset()
        var yOffset: CGFloat = 0

        // Drop existing top/bottom constraints owned by the queued toasts.
        let queued = Set(toastQueue.map(ObjectIdentifier.init))
        let toRemove = containerView.constraints.filter { constraint in
            if let firstItem = constraint.firstItem as? UIView,
               queued.contains(ObjectIdentifier(firstItem)),
               constraint.firstAttribute == .top || constraint.firstAttribute == .bottom {
                return true
            }
            if let secondItem = constraint.secondItem as? UIView,
               queued.contains(ObjectIdentifier(secondItem)),
               constraint.secondAttribute == .top || constraint.secondAttribute == .bottom {
                return true
            }
            return false
        }
        NSLayoutConstraint.deactivate(toRemove)

        for toastView in toastQueue.reversed() {
            guard let superview = toastView.superview else { continue }
            toastView.translatesAutoresizingMaskIntoConstraints = false

            let height = toastView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

            switch toastView.position {
            case .bottom, .bottomLeft, .bottomRight:
                toastView.bottomAnchor.constraint(
                    equalTo: superview.safeAreaLayoutGuide.bottomAnchor,
                    constant: yOffset - tabBarOffset
                ).isActive = true
                yOffset -= (height + toastPadding)
            case .bottomAboveTabBar, .bottomLeftAboveTabBar, .bottomRightAboveTabBar:
                let forcedOffset = tabBarOffset > 0 ? tabBarOffset : 49 + 16
                toastView.bottomAnchor.constraint(
                    equalTo: superview.safeAreaLayoutGuide.bottomAnchor,
                    constant: yOffset - forcedOffset
                ).isActive = true
                yOffset -= (height + toastPadding)
            case .top, .topLeft, .topRight:
                toastView.topAnchor.constraint(
                    equalTo: superview.safeAreaLayoutGuide.topAnchor,
                    constant: yOffset
                ).isActive = true
                yOffset += (height + toastPadding)
            case .center:
                toastView.centerYAnchor.constraint(
                    equalTo: superview.centerYAnchor,
                    constant: yOffset
                ).isActive = true
                yOffset -= (height + toastPadding)
            case .none:
                break
            }
        }

        UIView.animate(withDuration: 0.3) {
            containerView.layoutIfNeeded()
        }
    }

    /// Dismisses a specific toast.
    func dismiss(toast: ToastView, from containerView: UIView) {
        guard toastQueue.contains(toast) else { return }
        toast.dismiss { [weak self] in
            guard let self = self else { return }
            if let index = self.toastQueue.firstIndex(of: toast) {
                self.toastQueue.remove(at: index)
            }
            self.updateToastPositions(in: containerView)
        }
    }

    /// Dismisses the currently displayed toast (the first in the queue).
    public func cancelCurrentToast() {
        guard let currentToast = toastQueue.first else { return }
        currentToast.dismiss { [weak self] in
            guard let self = self else { return }
            if !self.toastQueue.isEmpty {
                self.toastQueue.removeFirst()
            }
            if let containerView = currentToast.superview {
                self.updateToastPositions(in: containerView)
            }
        }
    }

    /// Dismisses every queued and visible toast.
    public func cancelAllToasts() {
        let toasts = toastQueue
        toastQueue.removeAll()
        for toast in toasts {
            toast.dismiss()
        }
    }

    private func updateCurrentToastMessage() {
        guard let message = message else { return }
        toastQueue.first?.updateMessage(newMessage: message)
    }
}
