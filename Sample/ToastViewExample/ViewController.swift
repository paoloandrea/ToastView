//
//  ViewController.swift
//  ToastViewExample
//
//  Created by Paolo Rossignoli on 18.10.23.
//

import UIKit
import ToastView

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let image = UIImage(systemName: "star.fill")
        
        ToastView.show(message: "10:19 AM", image: image, isProgress: true, position: .bottom, withBackground: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            ToastView.dismiss()
        }
    }
    
    
}

