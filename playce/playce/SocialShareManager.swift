//
//  SocialShareManager.swift
//  playce
//
//  Created by Tys Bradford on 11/1/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit
import SDWebImage

class SocialShareManager: NSObject {
    
    
    static func getShareTextForItem(item:MusicItem) -> String {
        
        var shareText = "I'm listening to music on Playce"
        switch item.getItemType() {
        case .track:
            shareText = "I'm listening to " + (item.name ?? "music") + " on Playce"
        case .album:
            shareText = "I'm listening to " + (item.name ?? "music") + " on Playce"
        case .artist:
            shareText = "I'm listening to " + (item.name ?? "music") + " on Playce"
        case .playlist:
            shareText = "I'm listening to " + (item.name ?? "music") + " on Playce"
        default:
            break
        }
        return shareText
    }
    
    static func getShareURLForItem(item:MusicItem) -> URL {
        return URL(string: "http://www.playce.com")!
    }
    
    static func getShareImageForItem(item:MusicItem) -> UIImage? {
        
        if let imageURL = item.getImageURL() {
            return SDImageCache.shared().imageFromMemoryCache(forKey: imageURL.absoluteString)
        } else {return item.getLocalImage()}
    }

}
