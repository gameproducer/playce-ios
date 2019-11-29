//
//  AboutVC.swift
//  playce
//
//  Created by Tys Bradford on 9/2/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit

class AboutVC: UIViewController {

    
    @IBOutlet weak var webview: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "About"
        
        let aboutURL = URL(string: "http://www.playce.app")
        let request = URLRequest(url: aboutURL!)
        self.webview.loadRequest(request)
        self.webview.scalesPageToFit = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


}
