//
//  Artist.swift
//  playce
//
//  Created by Tys Bradford on 26/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MediaPlayer

class Artist: MusicItem {

    var popularity : Int?
    var itemCount : Int?
    
    override init(json: [String:AnyObject]) {
        
        self.popularity = json["popularity"] as? Int
        self.itemCount = json["track_count"] as? Int
        super.init(json: json)
    }
    
    init(mediaItemRep:MPMediaItem) {
        
        super.init()
        
        self.isLocal = true
        self.provider = "itunes"
        
        self.name = mediaItemRep.value(forProperty: MPMediaItemPropertyArtist) as? String
        self.mediaItem = mediaItemRep
        self.localID = mediaItemRep.value(forProperty: MPMediaItemPropertyArtistPersistentID) as?MPMediaEntityPersistentID
    
        self.itemCount = getItunesSongs().count
    }
    
    func getNumberOfSongs() -> Int {
        if itemCount != nil {return itemCount!}
        else {return 0}
    }
    
    func getNumberOfSongsString() -> String {
        
        let count = self.getNumberOfSongs()
        if count == 0 {
            return ""
        } else if count == 1 {
            return "1 Song"
        } else {
            return String (count) + " Songs"
        }
    }
    
    func getItunesSongs() -> [Song] {
        return ItunesHandler.sharedInstance.getSongsForArtist(item: self)
    }
    
}
