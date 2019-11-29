//
//  Playlist.swift
//  playce
//
//  Created by Tys Bradford on 26/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MediaPlayer

class Playlist: MusicItem {

    var itemCount : Int?
    var owner : String?
    
    override init(json: [String:AnyObject]) {
        
        self.itemCount = json["num_items"] as? Int
        self.owner = json["owner"] as? String
        super.init(json: json)
    }
    
    init(playlist:MPMediaPlaylist,item:MPMediaItem,count:Int) {
        
        super.init()
        
        self.isLocal = true
        self.provider = "itunes"
        self.itemCount = count
        
        self.name = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String
        self.mediaItem = item
        self.localID = playlist.value(forProperty: MPMediaPlaylistPropertyPersistentID) as?MPMediaEntityPersistentID
        
    }
    
    func getNumberOfSongs() -> Int {
        if itemCount != nil {return itemCount!}
        else {return 0}
    }
    
    func getNumberOfSongsString() -> String {
        
        let count = self.getNumberOfSongs()
        if count == 1 {
            return "1 Song"
        } else {
            return String (count) + " Songs"
        }
    }
    
    func isCustomPlaylist() -> Bool {
        if self.provider == nil {return true}
        else {return false}
    }
    
    
}
