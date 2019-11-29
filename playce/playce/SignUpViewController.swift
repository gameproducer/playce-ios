//
//  SignUpViewController.swift
//  playce
//
//  Created by Benjamin Hendricks on 5/21/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import Material

class SignUpViewController: UIViewController {

    var customLoadIndicator : CustomLoadIndicator?
    var originalViewOrigin: CGPoint = CGPoint.zero
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var nameTextField: TextField!
    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var confirmPasswordTextField: TextField!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var termsLabel: UILabel!
    
    
    
    override func viewDidLayoutSubviews() {
        facebookButton.layer.cornerRadius = facebookButton.bounds.size.height/2
        signUpButton.layer.cornerRadius = signUpButton.bounds.size.height/2
        
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        facebookButton.layer.cornerRadius = facebookButton.bounds.size.height/2
        signUpButton.layer.cornerRadius = signUpButton.bounds.size.height/2
        
        nameTextField.placeholder = "Full Name"
        emailTextField.placeholder = "Email"
        passwordTextField.placeholder = "Password"
        confirmPasswordTextField.placeholder = "Confirm Password"
        
        passwordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true;
        emailTextField.autocorrectionType = .no

        passwordTextField.visibilityIconButton?.tintColor = UIColor.darkGray
        confirmPasswordTextField.visibilityIconButton?.tintColor = UIColor.darkGray
        
        signInLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(SignUpViewController.signInLabelPressed(_:))))
        signInLabel.isUserInteractionEnabled = true
        
        backButton.imageView?.contentMode = .scaleAspectFit
        self.customLoadIndicator = CustomLoadIndicator(parentView: self.view)

        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil);
        originalViewOrigin = view.frame.origin
        
        let termsTap = UITapGestureRecognizer(target: self, action: #selector(didTapTermsLabel))
        self.termsLabel.addGestureRecognizer(termsTap)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        confirmPasswordTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
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

    @IBAction func signUpButtonPressed(_ sender: AnyObject) {
        guard let nameText = nameTextField.text,
            let emailText = emailTextField.text,
            let passwordText = passwordTextField.text,
            let confirmPasswordText = confirmPasswordTextField.text
            , nameTextField.hasText && emailTextField.hasText && passwordText == confirmPasswordText && passwordTextField.hasText else {
                let alertController = UIAlertController(title: "Invalid input params", message: "Please try again!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                
                present(alertController, animated: true, completion: nil)
                return
        }
        
        self.customLoadIndicator?.startAnimating()
        APIManager.sharedInstance.signUp(nameText, email: emailText, password: passwordText, completion: {
            success in
            self.customLoadIndicator?.stopAnimating()
            if success {
                self.performSegue(withIdentifier: "showChooseProviderViewControllerFromSignUp", sender: self)
            } else {
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
                if let token = result?.token.tokenString , (result?.grantedPermissions.contains("email"))! {
                    self.customLoadIndicator?.startAnimating()
                    APIManager.sharedInstance.signUpFacebook(token) {
                        success in
                        self.customLoadIndicator?.stopAnimating()
                        self.performSegue(withIdentifier: "showChooseProviderViewControllerFromSignUp", sender: self)
                    }
                } else {
                    self.showVerificationError()   
                }
            }
        })
    }
 
    @objc func signInLabelPressed(_ sender: AnyObject) {
        let _ = navigationController?.popViewController(animated: true)
        navigationController?.viewControllers[0].performSegue(withIdentifier: "showSignInViewController", sender: self)
    }
    
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        let _ = navigationController?.popViewController(animated: true)
    }
    
    func showVerificationError() {
        let alertController = UIAlertController(title: "A verification error occured", message: "Please check your details and try again", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: - Terms and policy
    @objc func didTapTermsLabel(gesture:UITapGestureRecognizer) {
        
        let tapLocation = gesture.location(in: gesture.view)
        let labelWidth = self.termsLabel.bounds.size.width
        let isLeftHalf = tapLocation.x <= labelWidth * 0.5
        if isLeftHalf {
            self.goToTerms()
        } else {
            self.goToPrivacy()
        }
    }
    
    func goToTerms() {
        if let termsURL = URL(string: "http://www.playce.app/terms-of-use") {
            UIApplication.shared.open(termsURL, options: [:], completionHandler: nil)

        }
    }
    
    func goToPrivacy() {
        if let privacyURL = URL(string: "http://www.playce.app/privacy") {
            UIApplication.shared.open(privacyURL, options: [:], completionHandler: nil)
        }
    }
    
}
