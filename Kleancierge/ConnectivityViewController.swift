//
//  ConnectivityViewController.swift
//  Kleancierge
//
//  Created by Vincent Moley on 8/15/18.
//  Copyright © 2018 Vincent Moley. All rights reserved.
//

import UIKit

class ConnectivityViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func attemptReconnect(_ sender: Any) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "webView")
        self.present(nextViewController, animated:true, completion:nil)
    }
}
