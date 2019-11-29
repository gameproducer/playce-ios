//
//  PasswordResetVC.swift
//  playce
//
//  Created by Tys Bradford on 15/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import Material

class PasswordResetVC: UIViewController {

    var customLoadIndicator : CustomLoadIndicator?

    @IBOutlet weak var emailField: TextField!
    @IBOutlet weak var sendButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Textfield
        self.emailField.placeholder = "Email"
        
        //Buttons
        self.sendButton.layer.cornerRadius = self.sendButton.frame.size.height*0.5
        self.sendButton.layer.masksToBounds = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - TextField delegate
    

    //MARK: - Button Handler
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func sendButtonPressed(_ sender: AnyObject) {
        
        /*
        let warningMessage = checkInputs() {
            
            showInputWarning(warningMessage!)
            return
        }
         */
    }
    
    func checkInputs()->String? {
        
        if self.emailField.hasText && (self.emailField.text?.contains("@"))! {
            return "Please enter a valid email address"
        }
        
        return nil
    }
    
    //MARK: - Alerts
    func showWarning(_ message:String?) {
        showAlert("Warning", message: message)
    }
    
    func showSuccess(_ message:String?) {
        showAlert("Success", message: message)
    }
    
    func showAlert(_ title:String?, message:String?) {
        
        guard let title = title else {return}
        guard let message = message else {return}
        
        let ac = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(ac, animated: true, completion: nil)
    }
    
    //MARK: Password Reset
    func resetPassword() {
        
        guard let email = emailField.text else {return}
        APIManager.sharedInstance.passwordReset(email) { (success) in
            if success {
                
                
            } else {
                self.showWarning("There was a problem resetting your password at this time. Please try again later.")
            }
        }
    }
    
    
    //MARK: Navigation
    func goToSignin() {
        
        self.navigationController?.popViewController(animated: true)
    }
    
}
