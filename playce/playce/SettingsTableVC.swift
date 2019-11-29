//
//  SettingsTableVC.swift
//  playce
//
//  Created by Tys Bradford on 15/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class SettingsTableVC: UITableViewController {

    enum SettingsItem: Int {
        case player = 0
        case streaming = 1
        case account = 2
        case platformSettings = 3
        case about = 4
        case logout = 5
    }
    
    let settingsItems = [SettingsItem.platformSettings,SettingsItem.about,SettingsItem.logout]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Navbar
        self.title = "Settings"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        let titleLabel = cell.viewWithTag(100) as? UILabel
        let iconImg = cell.viewWithTag(200) as? UIImageView
        
        if titleLabel == nil || iconImg == nil {
            return cell
        }
        
        let item = self.settingsItems[indexPath.row]
        switch (item.rawValue) {
        case SettingsItem.player.rawValue:
            titleLabel!.text = "Player"
            iconImg?.image = UIImage(named: "settings_player_ic")
        case SettingsItem.streaming.rawValue:
            titleLabel!.text = "Streaming"
            iconImg?.image = UIImage(named: "settings_streaming_ic")
        case SettingsItem.account.rawValue:
            titleLabel!.text = "Account"
            iconImg?.image = UIImage(named: "settings_account_ic")
        case SettingsItem.platformSettings.rawValue:
            titleLabel!.text = "Platform Settings"
            iconImg?.image = UIImage(named: "settings_platform_ic")
        case SettingsItem.about.rawValue:
            titleLabel!.text = "About"
            iconImg?.image = UIImage(named: "settings_about_ic")
        case SettingsItem.logout.rawValue:
            titleLabel!.text = "Logout"
            iconImg?.image = UIImage(named: "settings_account_ic")
        default: break
            
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = self.settingsItems[indexPath.row]
        switch (item.rawValue) {
        case SettingsItem.player.rawValue:
            goToPlayer()
        case SettingsItem.streaming.rawValue:
            goToStreaming()
        case SettingsItem.account.rawValue:
            goToAccount()
        case SettingsItem.platformSettings.rawValue:
            goToPlatformSettings()
        case SettingsItem.about.rawValue:
            goToAbout()
        case SettingsItem.logout.rawValue:
            showLogoutDialog()
        default: break
            
        }
    }
    
    
    // MARK: - Navigation
    
    func goToPlayer(){
        
    }
    
    func goToStreaming(){
        
    }
    
    func goToAccount(){
        
    }
    
    func goToPlatformSettings(){
        let storyboard = self.storyboard
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChooseProviderViewController") as? ChooseProviderViewController
        if vc != nil {
            vc?.isFromSettings = true
            self.navigationController?.pushViewController(vc!, animated: true)
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }
    
    func goToAbout(){
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "AboutVC") {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func showLogoutDialog() {
        let ac = UIAlertController(title: "Warning", message: "Are you sure you wish to log out?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            self.logout()
        }
        ac.addAction(cancelAction)
        ac.addAction(okAction)
        self.present(ac, animated: true, completion: nil)
    }
    
    func logout() {
        
        //Pause any playing music
        PlaybackHandler.sharedInstance.pausePlayback()
        
        UserHandler.sharedInstance.logout();
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.goToWelcome()
        }
        
        //Reset main VC
        if let menuVC = self.getSlideMenuVC() {
            menuVC.goToHomeReset()
        }
    }
}
