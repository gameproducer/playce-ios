//
//  UIViewController+Playback.swift
//  playce
//
//  Created by Tys Bradford on 7/10/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import Foundation
import SlideMenuControllerSwift

extension UIViewController {
    
    //MARK: - Helpers
    func getAppDelegate()->AppDelegate{
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func getPlaybackBar()->PlaybackBarVC{
        return self.getAppDelegate().playbackBarVC!
    }
    
    func getPlaybackFull()->PlaybackFullVC {
        return self.getAppDelegate().playbackFullVC!
    }
    
    func getSliderVC()->SlideMenuController {
        return self.getAppDelegate().slideVC!
    }
    
    func getMainVCView()->UIView? {
        return getSliderVC().mainContainerView
    }
    
    func getSlideMenuVC()->SlideMenuViewController? {
        if let containerVC = self.getSliderVC().leftViewController as? MenuContainerVC {
            return containerVC.slideMenuVC
        } else {
            return nil
        }
    }
    
    //MARK: - Hide/Show
    func showPlaybackBar(animated:Bool){
        
        //If not showing -> Add to top root VC (SliderMenuVC)
        if !self.isPlaybackBarShowing() {
            
            let screenHeight = self.getSliderVC().view.frame.size.height
            let barHeight = PlaybackBarVC.barHeight

            let originY = screenHeight - barHeight
            self.getPlaybackBar().view.setHeight(barHeight)
            if self.getPlaybackBar().view.superview == nil {
                self.getMainVCView()?.addSubview(self.getPlaybackBar().view)
            }
            
            self.getSliderVC().view.bringSubviewToFront(self.getPlaybackBar().view)

            if animated {
                self.getPlaybackBar().view.setOriginY(screenHeight)
                self.getPlaybackBar().view.isHidden = false
                UIView.animate(withDuration: 0.3, animations: {
                    self.getPlaybackBar().view.setOriginY(originY)
                })
            } else {
                self.getPlaybackBar().view.setOriginY(originY)
                self.getPlaybackBar().view.isHidden = false
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlaybackBarVC.playbackBarShownNotification), object: nil)
            self.getPlaybackBar().hasBeenShown = true;
        }
    }
    
    func hidePlaybackBar(animated:Bool){
        
        //Remove from rootVC
        self.getPlaybackBar().view.isHidden = true
        self.getPlaybackBar().view.removeFromSuperview()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: PlaybackBarVC.playbackBarHiddenNotification), object: nil)
    }
    
    
    func showPlaybackFull(){
        
        self.getPlaybackFull().view.isHidden = false
        self.getPlaybackFull().modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.getSliderVC().present(self.getPlaybackFull(), animated: true, completion: nil)
    }
    
    //MARK: - Status Bar
    func hideStatusBar() {
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func showStatusBar() {
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    func playSong(song:Song){
        
        //Show playbackBar if needed
        self.showPlaybackBar(animated: true)
        
        //Play song
        _ = PlaybackHandler.sharedInstance.playSong(songs: [song],clearQueue: true)
    }
    
    func playSongs(songs:[Song]) {
        
        if songs.count > 0 {
            //Show playbackBar if needed
            self.showPlaybackBar(animated: true)
            
            //Play song
            _ = PlaybackHandler.sharedInstance.playSong(songs: songs,clearQueue: true)
        }
    }
    
    func playSongsWithinList(song:Song,list:[Song]) {
        
        self.showPlaybackBar(animated: true)
        PlaybackHandler.sharedInstance.playSongFromWithinList(song: song, list: list)
    }
    
    //MARK: - Convenience
    func isPlaybackBarShowing()->Bool{
        guard let view = self.getPlaybackBar().view else {return false}
        if view.superview != self.getMainVCView() {return false}
        
        if let viewOrder = view.superview?.subviews.index(of: view) {
            if viewOrder != view.superview!.subviews.count - 1 {return false}
        }
        return !view.isHidden
    }
    
    func isPlaybackFullshowing()->Bool{
        return !self.getPlaybackFull().view.isHidden
    }
    
    func getPlaybackBarHeight()->CGFloat{
        return PlaybackBarVC.barHeight
    }
    
    
}
