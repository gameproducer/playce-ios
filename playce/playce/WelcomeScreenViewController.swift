//
//  WelcomeScreenViewController.swift
//  playce
//
//  Created by Benjamin Hendricks on 5/21/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class WelcomeScreenViewController: UIViewController {

    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UILabel!
    
    override func viewDidLayoutSubviews() {
        signUpButton.layer.cornerRadius = signUpButton.bounds.size.height/2
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let tapSignInButton = UITapGestureRecognizer(target: self, action: #selector(WelcomeScreenViewController.signInButtonTapped(_:)))
        signInButton.addGestureRecognizer(tapSignInButton)
        signInButton.isUserInteractionEnabled = true

    }
    
    @IBAction func signUpButtonPressed(_ sender: AnyObject) {
        performSegue(withIdentifier: "showSignUpViewController", sender: self)
    }
    
    @objc func signInButtonTapped(_ sender: AnyObject) {
        performSegue(withIdentifier: "showSignInViewController", sender: self)
    }
    
}
