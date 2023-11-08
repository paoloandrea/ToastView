//
//  ToastManager.swift
//  ToastViewExample
//
//  Created by Paolo Rossignoli on 05/11/23.
//

import UIKit

class ToastManager {
    
    static let shared = ToastManager()
    
    private init() {} // Private initialization to ensure only one instance is created.
    
    private var toastQueue = [ToastView]()
    private var isCurrentlyShowing = false
    public var allowMultipleToasts = false
    private var toastPadding: CGFloat = 4
    
    /// Shows a toast with given parameters.
    func showToast(message: String, image: UIImage? = nil, isProgress: Bool = false, position: ToastPosition = .center, duration: TimeInterval = 2.0, in view: UIView? = nil, withBackground: Bool = false) {
        
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
    
    /// Dismisses a specific toast.
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
    
    func cancelCurrentToast() {
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
    func cancelAllToasts() {
        while !toastQueue.isEmpty {
            let toast = toastQueue.removeLast()
            toast.dismiss() {
                toast.removeFromSuperview()
            }
        }
        
        isCurrentlyShowing = false
    }
}


#Preview() {
    ViewController()
}
