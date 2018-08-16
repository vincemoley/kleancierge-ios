//
//  SpinnerViewController.swift
//  Kleancierge
//
//  Created by Vincent Moley on 8/14/18.
//  Copyright © 2018 Vincent Moley. All rights reserved.
//

import UIKit

class SpinnerViewController: UIViewController {
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.0)
        
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        
        view.addSubview(spinner)
        
        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
