//
//  UITableViewController+Playback.swift
//  playce
//
//  Created by Tys Bradford on 12/10/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import Foundation


extension UITableViewController {



    func adjustForPlaybackBar(){
        
        if self.isPlaybackBarShowing() {
            self.setInsetsToPlaybackBar()
        } else {
            self.setInsetsToZero()
        }
        
        self.addListenersForPlaybackBarHideShow()
    }
    
    internal func setInsetsToPlaybackBar(){
        let navbarHeight = PlaybackBarVC.barHeight
        var insets = self.tableView.contentInset
        insets.bottom = navbarHeight
        
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
    }
    
    internal func setInsetsToZero() {
        var insets = self.tableView.contentInset
        insets.bottom = 0.0
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
    }


    func addListenersForPlaybackBarHideShow() {
        NotificationCenter.default.addObserver(self, selector: #selector(playbackBarWasShown), name: NSNotification.Name(PlaybackBarVC.playbackBarShownNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackBarWasHidden), name: NSNotification.Name(PlaybackBarVC.playbackBarHiddenNotification), object: nil)
    }
    
    func removeListenersForPlaybackHideShow() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(PlaybackBarVC.playbackBarShownNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(PlaybackBarVC.playbackBarHiddenNotification), object: nil)
    }
    
    @objc func playbackBarWasShown() {
        self.setInsetsToPlaybackBar()
    }
    
    @objc func playbackBarWasHidden() {
        self.setInsetsToZero()
    }
}
