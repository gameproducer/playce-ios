//
//  SlideMenuViewController.swift
//  playce
//
//  Created by Benjamin Hendricks on 6/4/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift

enum SlideMenuItem: Int {
    case discover = 0
    case songs = 1
    case artists = 2
    case albums = 3
    case playlists = 4
}

class SlideMenuViewController: UITableViewController {
    
    var selectionIndicator : UIView!
    @IBOutlet var menuTableView: UITableView!
    
    //VCs
    var discoverVC : DiscoverHomeVC?
    var mySongsVC : SongsViewController?
    var myAlbumsVC : AlbumTableVC?
    var myArtistsVC : ArtistTableVC?
    var myPlaylistVC : PlaylistTableVC?
    
    static let SLIDE_MENU_HIDE_INDICATOR_NOTIFICATION : String = "SLIDE_MENU_HIDE_INDICATOR_NOTIFICATION"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Create indicator
        selectionIndicator = createSelectionIndicator()
        let cell = getTableCellForIndex(0)
        selectMenuItem(cell)

        if !UserHandler.sharedInstance.isUserLoggedIn() {
            self.goToWelcome()
        }
        
        //Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(SlideMenuViewController.hideSelectionIndicator), name: NSNotification.Name(rawValue: SlideMenuViewController.SLIDE_MENU_HIDE_INDICATOR_NOTIFICATION), object: nil)

    }
    
    func goToWelcome() {
        
        // Show login
        guard let window = UIApplication.shared.keyWindow else {return}
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let navController = storyboard.instantiateViewController(withIdentifier: "WelcomeScreenNavigationViewController")
        
        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = navController
        }, completion: nil)

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        var newMainVC = UIViewController()
        switch (indexPath as NSIndexPath).row {
        case SlideMenuItem.discover.rawValue:
            if self.discoverVC == nil {
                self.discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverHomeVC") as? DiscoverHomeVC
            }
            newMainVC = self.discoverVC!
            break
        case SlideMenuItem.songs.rawValue:
            if self.mySongsVC == nil {
                self.mySongsVC = storyboard.instantiateViewController(withIdentifier: "SongsViewController") as? SongsViewController
            }
            newMainVC = self.mySongsVC!
            break
        case SlideMenuItem.artists.rawValue:
            if self.myArtistsVC == nil {
                self.myArtistsVC = storyboard.instantiateViewController(withIdentifier: "ArtistTableVC") as? ArtistTableVC
            }
            newMainVC = self.myArtistsVC!
            break
        case SlideMenuItem.albums.rawValue:
            if self.myAlbumsVC == nil {
                self.myAlbumsVC = storyboard.instantiateViewController(withIdentifier: "AlbumTableVC") as? AlbumTableVC
            }
            newMainVC = self.myAlbumsVC!
            break
        case SlideMenuItem.playlists.rawValue:
            if self.myPlaylistVC == nil {
                self.myPlaylistVC = storyboard.instantiateViewController(withIdentifier: "PlaylistTableVC") as? PlaylistTableVC
            }
            newMainVC = self.myPlaylistVC!
            break
        default:
            if self.discoverVC == nil {
                self.discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverHomeVC") as? DiscoverHomeVC
            }
            newMainVC = self.discoverVC!
            break
        }
        
        //Set selection indicator
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectMenuItem(selectedCell)
        hideSettingsIndicator()
        
        //Change main VC
        guard let slideMenu = slideMenuController() else {return}
        var navController = slideMenu.mainViewController as? PLNavController
        if navController == nil {
            navController = PLNavController()
        }
        
        let wasPlaybarShowing = self.getPlaybackBar().hasBeenShown
        if wasPlaybarShowing {self.hidePlaybackBar(animated: false)}
        
        navController?.viewControllers = [newMainVC]
        slideMenu.changeMainViewController(navController!, close: true)
        if wasPlaybarShowing {self.showPlaybackBar(animated: false)}
    }
    
    fileprivate func getTableCellForIndex(_ index: Int) -> UITableViewCell?{
        
        return self.tableView(self.tableView, cellForRowAt: IndexPath(row: index, section: 0))
    }
    
    fileprivate func selectMenuItem(_ cell : UITableViewCell?) {
        
        if selectionIndicator == nil {
            selectionIndicator = createSelectionIndicator()
        }
        
        //Remove from current superview
        if selectionIndicator.superview != nil {
            selectionIndicator.removeFromSuperview()
        }
        
        //Set new parentView
        if cell != nil{
            cell!.addSubview(selectionIndicator)
            selectionIndicator.isHidden = false
        } else {

        }
    }
    
    fileprivate func createSelectionIndicator() -> UIView {
        
        let view = UIView(frame: CGRect(origin: CGPoint(x: 0.0, y: 6.0), size: CGSize(width: 4.0, height: 58.0)))
        view.backgroundColor = UIColor(red:0.24, green:0.72, blue:0.67, alpha:1.0)
        return view
    }
    
    @objc func hideSelectionIndicator() {
        
        if selectionIndicator != nil {
            selectionIndicator.isHidden = true
        }
    }
    
    func hideSettingsIndicator(){
        
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: MenuContainerVC.HIDE_SETTINGS_INDICATOR_NOTIFICATION), object: nil)
    }
    
    func goToHomeReset() {
        
        let selectedCell = tableView.cellForRow(at: IndexPath(item:0,section:0))
        selectMenuItem(selectedCell)
        hideSettingsIndicator()
        
        guard let slideMenu = slideMenuController() else {return}
        var navController = slideMenu.mainViewController as? PLNavController
        if navController == nil {navController = PLNavController()}
        
        self.hidePlaybackBar(animated: false)
        
        var discoverVC = self.discoverVC
        if discoverVC == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverHomeVC") as? DiscoverHomeVC
        }
        navController?.viewControllers = [discoverVC!]
        slideMenu.changeMainViewController(navController!, close: true)
    }
}
