//
//  PlaybackInfoCenterController.swift
//  playce
//
//  Created by Tys Bradford on 5/2/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit
import MediaPlayer
import SDWebImage

class PlaybackInfoCenterController: NSObject {

    
    static let sharedInstance : PlaybackInfoCenterController = PlaybackInfoCenterController()


    override init() {
        super.init()
        
        UIApplication.shared.beginReceivingRemoteControlEvents();
        
        MPRemoteCommandCenter.shared().playCommand.addTarget {event in
            PlaybackHandler.sharedInstance.resumePlayback()
            self.updateNowPlayingInfoCenter()
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget {event in
            PlaybackHandler.sharedInstance.pausePlayback()
            return .success
        }
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget {event in
            PlaybackHandler.sharedInstance.skipPlaybackForward()
            return .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget {event in
            PlaybackHandler.sharedInstance.skipPlaybackBackwards()
            return .success
        }
    }
    
    
    func updateNowPlayingInfoCenter() {
        
        guard let currentTrack = PlaybackHandler.sharedInstance.currentSong else {return}
        
        //Meta
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle : currentTrack.name ?? "",
            MPMediaItemPropertyArtist : currentTrack.getArtistNameString(),
            MPMediaItemPropertyPlaybackDuration : currentTrack.getSongDurationSeconds(),
            MPNowPlayingInfoPropertyElapsedPlaybackTime : PlaybackHandler.sharedInstance.getCurrentSongTime() ?? 0.0
        ]
        
        //Artwork
        if let imgURL = currentTrack.getImageURL() {
            if let image = SDWebImageManager.shared().imageCache.imageFromMemoryCache(forKey: imgURL.absoluteString) {
                let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                    image
                })
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
            } else if let image = SDWebImageManager.shared().imageCache.imageFromDiskCache(forKey: imgURL.absoluteString) {
                let artwork = MPMediaItemArtwork.init(boundsSize: image.size, requestHandler: { (size) -> UIImage in
                    image
                })
                MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
            }
        } else if currentTrack.isLocal{
            guard let localImage = currentTrack.getLocalImage() else {return}
            let artwork = MPMediaItemArtwork.init(boundsSize: localImage.size, requestHandler: { (size) -> UIImage in
                localImage
            })
            MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
        }
    }
    
    func clearNowPlayingInfoCenter() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    
}
