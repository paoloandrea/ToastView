//
//  ToastManager.swift
//  ToastViewExample
//
//  Created by Paolo Rossignoli on 05/11/23.
//

import UIKit
/// The `ToastManager` class is a singleton that manages the display of toast messages on the screen.
/// It ensures that only one instance of the manager exists and controls the queuing and displaying of toasts.
/// It provides functionality to show, dismiss, and cancel toasts with various configurations.
public final class ToastManager {
    /// The shared instance of `ToastManager`.
    public static let shared = ToastManager()
    
    /// Private initialization to ensure only one instance is created.
    private init() {}
    
    /// The queue that holds the `ToastView` objects that are waiting to be displayed.
    private var toastQueue = [ToastView]()
    
    /// A boolean value indicating whether a toast is currently being displayed.
    public var isCurrentlyShowing = false
    
    /// A boolean value that determines whether multiple toasts can be shown at once.
    /// The default value is `false`, meaning only one toast will be shown at a time.
    public var allowMultipleToasts = false
    
    /// The padding between toasts when multiple toasts are displayed.
    private var toastPadding: CGFloat = 4
    
    /// Shows a toast message with optional image, progress, position, duration, view, and background settings.
    /// - Parameters:
    ///   - message: The message to be displayed on the toast.
    ///   - image: An optional image to display on the toast.
    ///   - isProgress: A boolean indicating if the toast is showing a progress indicator.
    ///   - position: The position on the screen where the toast will be displayed.
    ///   - duration: The time interval the toast will be on screen before auto-dismissing.
    ///   - view: An optional view to add the toast to. If not provided, the toast will be added to the key window.
    ///   - withBackground: A boolean indicating if the toast should be displayed with a background.
    public func showToast(message: String, image: UIImage? = nil, isProgress: Bool = false, position: ToastPosition = .center, duration: TimeInterval = 2.0, in view: UIView? = nil, withBackground: Bool = false) {
        
        let containerView = view ?? UIApplication.shared.keyWindow ?? UIView()
        
        if !allowMultipleToasts && isCurrentlyShowing {
            return
        }
        
        let toast = ToastView()
        toast.prepareToShow(message: message, image: image, isProgress: isProgress, position: position, duration: duration, withBackground: withBackground)
        
        toastQueue.append(toast)
        containerView.addSubview(toast)
        
        // Update positions of toasts in the queue
        updateToastPositions(in: containerView)
        
    }
    
    /// Updates the positions of all the toasts in the queue within the container view.
    /// It respects the `allowMultipleToasts` setting and adjusts the layout constraints accordingly.
    /// - Parameter containerView: The `UIView` that contains the toasts.
    private func updateToastPositions(in containerView: UIView) {
        guard allowMultipleToasts else { return }
        var yOffset:CGFloat = 0
        // Rimuove tutti i vecchi vincoli di tipo top o bottom
        NSLayoutConstraint.deactivate(
            containerView.constraints.filter { constraint in
                if let firstItem = constraint.firstItem as? UIView, toastQueue.contains(where: { $0 == firstItem }) {
                    return constraint.firstAttribute == .top || constraint.firstAttribute == .bottom
                }
                if let secondItem = constraint.secondItem as? UIView, toastQueue.contains(where: { $0 == secondItem }) {
                    return constraint.secondAttribute == .top || constraint.secondAttribute == .bottom
                }
                return false
            }
        )
        
        for toastView in toastQueue.reversed() {
            guard let superview = toastView.superview else { continue }
            toastView.translatesAutoresizingMaskIntoConstraints = false
            
            // Calcola l'altezza del toast qui, se necessario.
            let height = toastView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            
            switch toastView.position {
            case .bottom, .bottomLeft, .bottomRight:
                let bottomConstraint = toastView.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: yOffset)
                bottomConstraint.isActive = true
                yOffset -= (height + toastPadding) // Aggiorna yOffset per il prossimo toast
            case .top, .topLeft, .topRight:
                let topConstraint = toastView.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: yOffset)
                topConstraint.isActive = true
                yOffset += (height + toastPadding) // Aggiorna yOffset per il prossimo toast
            case .center:
                let centerConstraint = toastView.centerYAnchor.constraint(equalTo: superview.centerYAnchor, constant: yOffset)
                centerConstraint.isActive = true
                yOffset -= (height + toastPadding)   // Sposta verso il basso per il prossimo toast centrato
                //yOffset -= (height + toastPadding)  // Sposta verso l'alto per il prossimo toast centrato
            case .none:
                break
            }
        }
        
        // Anima le modifiche del layout.
        UIView.animate(withDuration: 0.3) {
            containerView.layoutIfNeeded()
        }
    }
    
    /// Dismisses a specific toast view from the screen and from the queue.
    /// - Parameters:
    ///   - toast: The `ToastView` object that needs to be dismissed.
    ///   - containerView: The `UIView` that contains the toast.
    func dismiss(toast: ToastView, from containerView: UIView) {
        guard toastQueue.contains(toast) else { return }
        
        toast.dismiss() {
            // Remove the toast from the queue
            if let index = self.toastQueue.firstIndex(of: toast) {
                self.toastQueue.remove(at: index)
            }
            
            // Remove the toast view from the superview
            toast.removeFromSuperview()
            
            self.isCurrentlyShowing = !self.toastQueue.isEmpty
            
            // Update positions of remaining toasts in the queue
            self.updateToastPositions(in: containerView)
        }
    }
    
    /// Cancels and dismisses the currently displayed toast, if any, and updates the queue and positions of remaining toasts.
    public func cancelCurrentToast() {
        // Se c'è un toast attualmente mostrato, lo rimuove
        guard let currentToast = toastQueue.first else { return }
        
        currentToast.dismiss() {
            // Rimuovi il toast corrente dalla coda
            self.toastQueue.removeFirst()
            self.isCurrentlyShowing = false
            
            // Aggiorna la posizione dei restanti toasts nella coda
            if let containerView = currentToast.superview {
                self.updateToastPositions(in: containerView)
            }
        }
    }
    
    /// Cancels and clears all queued and currently displayed toasts.
    /// This will remove all `ToastView` objects from the screen and empty the queue.
    public func cancelAllToasts() {
        while !toastQueue.isEmpty {
            let toast = toastQueue.removeLast()
            toast.dismiss() {
                toast.removeFromSuperview()
            }
        }
        
        isCurrentlyShowing = false
    }
}
