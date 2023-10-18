//
//  Toast.swift
//  IPTV_Components
//
//  Created by Paolo Rossignoli on 14/09/23.
//

import UIKit

enum ToastPosition {
    case topLeft, top, topRight, center, bottomLeft, bottom, bottomRight
}

class ToastView: UIView {
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let toastLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
#if os(iOS)
        label.font = .systemFont(ofSize: 17)
#elseif os(tvOS)
        label.font = .systemFont(ofSize: 29)
        #endif
        label.textAlignment = .center
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
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private var duration: TimeInterval = 0.0
    private var labelPadding: CGFloat = 20.0
    #if os(iOS)
    private static let imageSize = 29.0
    #elseif os(tvOS)
    private static let imageSize = 44.0
    #endif
    private static let toastPadding = 3.0
    
    static var activeToasts: [ToastView] = []
    
    static func show(message: String, image: UIImage? = nil, isProgress: Bool = false, position: ToastPosition = .center, duration: TimeInterval = 0, in view: UIView? = nil) {
        let toastView = ToastView()
        toastView.duration = duration
        toastView.toastLabel.text = message
        
        if let image = image {
            toastView.iconImageView.image = image.withTintColor(.white)
            toastView.stackView.insertArrangedSubview(toastView.iconImageView, at: 0)
            toastView.iconImageView.widthAnchor.constraint(equalToConstant: ToastView.imageSize).isActive = true
            toastView.iconImageView.heightAnchor.constraint(equalToConstant: ToastView.imageSize).isActive = true
        } else if isProgress {
            toastView.stackView.insertArrangedSubview(toastView.activityIndicator, at: 0)
            toastView.activityIndicator.startAnimating()
        }
        
        let superview: UIView
        if let customView = view {
            superview = customView
        } else if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            superview = keyWindow
        } else {
            return
        }
        
        superview.addSubview(toastView)
        
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        switch position {
        case .topLeft:
            NSLayoutConstraint.activate([
                toastView.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: ToastView.toastPadding),
                toastView.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: ToastView.toastPadding),
            ])
        case .top:
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor),
                toastView.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: ToastView.toastPadding),
            ])
        case .topRight:
            NSLayoutConstraint.activate([
                toastView.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -ToastView.toastPadding),
                toastView.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor, constant: ToastView.toastPadding),
            ])
        case .center:
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor),
                toastView.centerYAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerYAnchor),
            ])
        case .bottomLeft:
            NSLayoutConstraint.activate([
                toastView.leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor, constant: ToastView.toastPadding),
                toastView.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -ToastView.toastPadding),
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                toastView.centerXAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.centerXAnchor),
                toastView.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -ToastView.toastPadding),
            ])
        case .bottomRight:
            NSLayoutConstraint.activate([
                toastView.trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor, constant: -ToastView.toastPadding),
                toastView.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: -ToastView.toastPadding),
            ])
        }
        
        toastView.alpha = 0.0
        
        UIView.animate(withDuration: 0.3, animations: {
            toastView.alpha = 1.0
        }) { _ in
            if duration > 0.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    toastView.dismiss()
                }
            }
        }
        
        activeToasts.append(toastView)
    }
    
    private init() {
        super.init(frame: .zero)
        
        let blurEffect = UIBlurEffect(style: .dark)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)
        
        backgroundColor = .clear
        
        addSubview(stackView)
        stackView.addArrangedSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -labelPadding),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -0),
        ])
        
        layer.cornerRadius = 30
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
            if let index = ToastView.activeToasts.firstIndex(of: self) {
                ToastView.activeToasts.remove(at: index)
            }
        }
    }
    
    static func dismiss() {
        for toast in activeToasts {
            toast.dismiss()
        }
        //activeToasts.first?.dismiss()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}




#if compiler(>=5.9)
#Preview {
    let controller = UIViewController()
    controller.view.backgroundColor = .green
    let image = UIImage(systemName: "star.fill")
    let view = UIView(frame: CGRect(x: 1000, y: 64, width: 150, height: 60))
    view.backgroundColor = .red
    controller.view.addSubview(view)
    ToastView.show(message: "10:19 AM", image: image, isProgress: true, position: .bottom)
    /*
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        ToastView.dismiss()
    }
*/
    return controller
}
#endif
