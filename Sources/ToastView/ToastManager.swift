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
        toastQueue.append(toast)
        toast.prepareToShow(message: message,
                            image: image,
                            isProgress: isProgress,
                            position: position,
                            duration: duration,
                            in: containerView,
                            withBackground: withBackground,
                            completion: { [weak self, weak toast] in
                                guard let self = self,
                                      let toast = toast else { return }
                                self.removeToast(toast, from: containerView)
                            })

        updateToastPositions(in: containerView)
    }

    /// Recalculates stacked positions when `allowMultipleToasts` is `true`.
    private func updateToastPositions(in containerView: UIView) {
        guard allowMultipleToasts else { return }

        let tabBarOffset = containerView.toast_tabBarOffset()
        var topOffset: CGFloat = ToastView.edgePadding
        var centerOffset: CGFloat = 0
        var bottomOffset: CGFloat = -(ToastView.edgePadding + tabBarOffset)
        var forcedBottomOffset: CGFloat = -(ToastView.edgePadding + ToastView.fallbackTabBarOffset)

        for toastView in toastQueue.reversed() {
            guard let superview = toastView.superview else { continue }
            toastView.translatesAutoresizingMaskIntoConstraints = false

            let height = toastView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height

            switch toastView.position {
            case .bottom, .bottomLeft, .bottomRight:
                toastView.replaceVerticalConstraint(with: toastView.bottomAnchor.constraint(
                    equalTo: superview.safeAreaLayoutGuide.bottomAnchor,
                    constant: bottomOffset
                ))
                bottomOffset -= (height + toastPadding)
            case .bottomAboveTabBar, .bottomLeftAboveTabBar, .bottomRightAboveTabBar:
                if tabBarOffset > 0 {
                    toastView.replaceVerticalConstraint(with: toastView.bottomAnchor.constraint(
                        equalTo: superview.safeAreaLayoutGuide.bottomAnchor,
                        constant: bottomOffset
                    ))
                    bottomOffset -= (height + toastPadding)
                } else {
                    toastView.replaceVerticalConstraint(with: toastView.bottomAnchor.constraint(
                        equalTo: superview.safeAreaLayoutGuide.bottomAnchor,
                        constant: forcedBottomOffset
                    ))
                    forcedBottomOffset -= (height + toastPadding)
                }
            case .top, .topLeft, .topRight:
                toastView.replaceVerticalConstraint(with: toastView.topAnchor.constraint(
                    equalTo: superview.safeAreaLayoutGuide.topAnchor,
                    constant: topOffset
                ))
                topOffset += (height + toastPadding)
            case .center:
                toastView.replaceVerticalConstraint(with: toastView.centerYAnchor.constraint(
                    equalTo: superview.safeAreaLayoutGuide.centerYAnchor,
                    constant: centerOffset
                ))
                centerOffset -= (height + toastPadding)
            case .none:
                break
            }
        }

        UIView.animate(withDuration: 0.3) {
            containerView.layoutIfNeeded()
        }
    }

    private func removeToast(_ toast: ToastView, from containerView: UIView) {
        guard let index = toastQueue.firstIndex(of: toast) else { return }
        toastQueue.remove(at: index)
        updateToastPositions(in: containerView)
    }

    /// Dismisses a specific toast.
    func dismiss(toast: ToastView, from containerView: UIView) {
        guard toastQueue.contains(toast) else { return }
        toast.dismiss { [weak self, weak toast] in
            guard let self = self,
                  let toast = toast else { return }
            self.removeToast(toast, from: containerView)
        }
    }

    /// Dismisses the currently displayed toast (the first in the queue).
    public func cancelCurrentToast() {
        guard let currentToast = toastQueue.first,
              let containerView = currentToast.containerView else { return }
        currentToast.dismiss { [weak self, weak currentToast] in
            guard let self = self,
                  let currentToast = currentToast else { return }
            self.removeToast(currentToast, from: containerView)
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
