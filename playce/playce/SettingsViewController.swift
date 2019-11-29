//
//  SettingsViewController.swift
//  playce
//
//  Created by Benjamin Hendricks on 6/6/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var connectProviders: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signOutPressed(_ sender: AnyObject) {
        
        UserHandler.sharedInstance.logout()
        
        // show login
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let welcomeScreen = storyboard.instantiateViewController(withIdentifier: "WelcomeScreenNavigationViewController")
        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = welcomeScreen
            }, completion: nil)
        
    }

    @IBAction func connectProvidersPressed(_ sender: AnyObject) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let welcomeScreen = storyboard.instantiateViewController(withIdentifier: "ChooseProviderViewController")
        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = welcomeScreen
            }, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
