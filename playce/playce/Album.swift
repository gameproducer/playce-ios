//
//  Album.swift
//  playce
//
//  Created by Tys Bradford on 26/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MediaPlayer

class Album: MusicItem {

    var itemCount : Int?
    var artistName : String?
    var artistList : [Artist]?

    
    override init(json: [String:AnyObject]) {
     
        self.itemCount = json["num_items"] as? Int
        self.artistName = json["artist"] as? String
        super.init(json: json)
        self.artistList = createArtistList(json["artists"] as? [[String:AnyObject]])

    }
    
    init(mediaItemRep:MPMediaItem) {
        
        super.init()
        
        self.isLocal = true
        self.provider = "itunes"
        
        self.name = mediaItemRep.value(forProperty: MPMediaItemPropertyAlbumTitle) as? String
        self.artistName = mediaItemRep.value(forProperty: MPMediaItemPropertyAlbumArtist) as? String
        self.mediaItem = mediaItemRep
        
        self.localID = mediaItemRep.value(forProperty: MPMediaItemPropertyAlbumPersistentID) as?MPMediaEntityPersistentID
    }
    
    
    
    func createArtistList(_ list:[[String:AnyObject]]?) -> [Artist]?{
        
        guard let list = list else {return nil}
        var artists : [Artist] = []
        for dict in list {
            let artist = Artist(json:dict)
            artists.append(artist)
        }
        return artists
    }
    
    func getArtistNameString() -> String {
        
        if self.isLocal {
            if let name = self.artistName {return name}
            else {return ""}
        }
        
        if self.artistList == nil {return ""}
        var nameArray : [String] = []
        for artist in self.artistList! {
            if artist.name != nil {nameArray.append(artist.name!)}
        }
        return nameArray.joined(separator: ", ")
    }
}
