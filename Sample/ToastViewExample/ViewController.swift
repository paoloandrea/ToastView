//
//  ViewController.swift
//  ToastViewExample
//
//  Created by Paolo Rossignoli on 18.10.23.
//

import UIKit

class ViewController: UIViewController {
    private lazy var background:UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "background"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var stackView:UIStackView = {
       let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        return stackView
    }()
    
    private lazy var titleLabel : UILabel = {
       let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.text = "ToastView"
        label.textColor = .white
        return label
    }()
    
    private lazy var descriptionLabel : UILabel = {
       let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Easily display toast messages with optional icons, progress indicators, and blurred backgrounds in your iOS app."
        label.textColor = .white
        return label
    }()
    
    private lazy var buttonA : UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Message ++", for: .normal)
        button.addAction(UIAction { [weak self] action in
            self?.showMessage()
        }, for: .touchUpInside)
        return button
    }()
    private lazy var buttonB : UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Image and Message", for: .normal)
        button.addAction(UIAction { [weak self] action in
            self?.showImageAndMessage()
        }, for: .touchUpInside)
        return button
    }()
    private lazy var buttonC : UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Progress and Message", for: .normal)
        button.addAction(UIAction { [weak self] action in
            self?.showProgressAndMessage()
        }, for: .touchUpInside)
        return button
    }()
    private lazy var buttonD : UIButton = {
        let button = UIButton(configuration: .filled())
        button.setTitle("Message and blur background", for: .normal)
        button.addAction(UIAction { [weak self] action in
            self?.showMessageAndBackground()
        }, for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
        setupConstraint()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupConstraint() {
        self.view.addSubview(background)
        self.view.addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(descriptionLabel)
        stackView.addArrangedSubview(buttonA)
        stackView.addArrangedSubview(buttonB)
        stackView.addArrangedSubview(buttonC)
        stackView.addArrangedSubview(buttonD)
        
        NSLayoutConstraint.activate([
            background.topAnchor.constraint(equalTo: self.view.topAnchor),
            background.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            background.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            background.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            
            stackView.widthAnchor.constraint(equalToConstant: 300),
            stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
    }
    
    
   let toast = ToastManager.shared
    @IBAction func showMessage(){
        toast.allowMultipleToasts = true
        toast.showToast(message: "10:19 AM", position: .bottom)
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                //self.toast.cancelCurrentToast()
                self.toast.cancelAllToasts()
            }
    }
    
    @IBAction func showImageAndMessage(){
        let image = UIImage(systemName: "star.fill")
        toast.allowMultipleToasts = true
        toast.showToast(message: "10:19 AM", image: image, position: .center)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            //self.toast.cancelCurrentToast()
        }
    }
    
    @IBAction func showProgressAndMessage(){
        toast.allowMultipleToasts = true
        toast.showToast(message: "Add more toast to test tex in two different line, start with this information, Add more toast to test tex in two different line, start with this information", isProgress: true, position: .top)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            //ToastManager.shared.cancelCurrentToast()
        }
    }
    
    @IBAction func showMessageAndBackground(){
        toast.allowMultipleToasts = false
        toast.showToast(message: "10:19 AM", isProgress: true, position: .center, withBackground: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.toast.cancelCurrentToast()
        }
    }
    
}

@available(iOS 17.0, *)
#Preview() {
    ViewController()
}
