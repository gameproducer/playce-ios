//
//  MenuContainerVC.swift
//  playce
//
//  Created by Tys Bradford on 13/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class MenuContainerVC: UIViewController {

    @IBOutlet weak var settingsSubView: UIView!
    @IBOutlet weak var settingsIndicator: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var slideMenuVC : SlideMenuViewController!
    
    static let HIDE_SETTINGS_INDICATOR_NOTIFICATION : String = "HIDE_SETTINGS_INDICATOR_NOTIFICTION"
    
    override func viewDidLoad() {
        super.viewDidLoad()


        //Add tap recogniser to settings
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(MenuContainerVC.goToSettings))
        settingsSubView.addGestureRecognizer(tap)
        
        //Hide settings indicator
        hideSettingsIndicator()
        
        //Notification handler
        NotificationCenter.default.addObserver(self, selector: #selector(MenuContainerVC.hideSettingsIndicator), name: NSNotification.Name(rawValue: MenuContainerVC.HIDE_SETTINGS_INDICATOR_NOTIFICATION), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Adjust for playback bar
        if self.isPlaybackBarShowing() {
            self.bottomConstraint.constant = self.getPlaybackBarHeight()
        } else {
            self.bottomConstraint.constant = 0.0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "tableEmbedSegue" {
            self.slideMenuVC = segue.destination as! SlideMenuViewController
        }
    }
    
    
    
    @objc func goToSettings(){
    
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsTableVC")
        
        guard let slideMenu = slideMenuController() else {return}
        let navController = PLNavController()
        
        navController.viewControllers = [settingsVC]
        showSettingsIndicator()
        hideMenuSelectionIndicator()
        slideMenu.changeMainViewController(navController, close: true)

    }
    
    func showSettingsIndicator() {
        settingsIndicator.isHidden = false
    }
    
    @objc func hideSettingsIndicator(){
        settingsIndicator.isHidden = true
    }
    
    func hideMenuSelectionIndicator() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: SlideMenuViewController.SLIDE_MENU_HIDE_INDICATOR_NOTIFICATION), object: nil)
    }
    
    

}
