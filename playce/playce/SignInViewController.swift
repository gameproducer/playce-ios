//
//  SignInViewController.swift
//  playce
//
//  Created by Benjamin Hendricks on 5/25/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import Material
import SlideMenuControllerSwift


class SignInViewController: UIViewController {

    var customLoadIndicator : CustomLoadIndicator?

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var signUpLabel: UILabel!
    
    override func viewDidLayoutSubviews() {
        facebookButton.layer.cornerRadius = facebookButton.bounds.size.height/2
        signInButton.layer.cornerRadius = signInButton.bounds.size.height/2
        
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emailTextField.placeholder = "Email"
        passwordTextField.placeholder = "Password"
        passwordTextField.isSecureTextEntry = true
        emailTextField.autocorrectionType = .no
        

        signUpLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SignInViewController.signUpLabelPressed(_:))))
        signUpLabel.isUserInteractionEnabled = true
        
        backButton.imageView?.contentMode = .scaleAspectFit
        
        let existingText = signUpLabel.text ?? ""
        let signUpLabelAttributedString = NSMutableAttributedString(string: existingText)
        let range = NSMakeRange(0, existingText.count - "SIGN UP".count)
        signUpLabelAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.lightGray, range: range)
        signUpLabel.attributedText = signUpLabelAttributedString

        self.customLoadIndicator = CustomLoadIndicator(parentView: self.view)

        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.keyboardWillShow(_:)), name:UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(SignInViewController.keyboardWillHide(_:)), name:UIResponder.keyboardWillHideNotification, object: nil);
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        super.touchesBegan(touches, with: event)
    }
    
    func viewMovedUp(_ movedUp: Bool) {
        var rect: CGRect = view.frame
        
        if movedUp {
            rect.origin.y -= 150
            rect.size.height += 150
        } else {
            rect.origin.y += 150
            rect.size.height -= 150
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            self.view.frame = rect
        })
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        if (self.view.frame.origin.y >= 0)
        {
            viewMovedUp(true)
        }
    }
    @objc func keyboardWillHide(_ sender: Notification) {
        if (self.view.frame.origin.y < 0)
        {
            viewMovedUp(false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func signUpLabelPressed(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
        navigationController?.viewControllers[0].performSegue(withIdentifier: "showSignUpViewController", sender: self)
    }

    @IBAction func backButtonPressed(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func signInButtonPressed(_ sender: AnyObject) {
        guard let emailText = emailTextField.text,
            let passwordText = passwordTextField.text , emailText.count > 0 && passwordText.count > 0 else {
                showVerificationError()
                return
        }
        
        self.customLoadIndicator?.startAnimating()
        APIManager.sharedInstance.signIn(emailText, password: passwordText, completion: {
            success in
            self.customLoadIndicator?.stopAnimating()
            if success {
                // go to Home
                self.goToHome()
                //self.performSegue(withIdentifier: "showChooseProviderViewControllerFromSignIn", sender: self)
            } else {
                // show error
                self.showVerificationError()
            }
        })
    }
    
    @IBAction func facebookButtonPressed(_ sender: AnyObject) {
        let loginManager = FBSDKLoginManager()
        loginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self, handler: {
            result, error in
            if error != nil {
                self.showVerificationError()
            } else if (result?.isCancelled)! {
                self.showVerificationError()
            } else {
                print(result)
                if let token = result?.token.tokenString , (result?.grantedPermissions.contains("email"))! {
                    self.customLoadIndicator?.startAnimating()
                    APIManager.sharedInstance.signUpFacebook(token) {
                        success in
                        self.customLoadIndicator?.stopAnimating()
                        self.goToHome()
                    }
                } else {
                    self.showVerificationError()
                }
            }
        })
    }
    
    func showVerificationError() {
        let alertController = UIAlertController(title: "A verification error occured", message: "Please check your details and try again", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func goToHome() {
        
        guard let window = UIApplication.shared.keyWindow else {return}
        
        //Update players
        PlaybackHandler.sharedInstance.updateProviders()
        
        //Go to home
        let slideVC = self.getSliderVC()
        let discoverVC = self.storyboard!.instantiateViewController(withIdentifier: "DiscoverHomeVC")
        let navController = PLNavController()
        navController.viewControllers = [discoverVC]
        slideVC.mainViewController = navController

        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = slideVC
        }, completion: nil)
    }
    
}
