//
//  Song.swift
//  playce
//
//  Created by Tys Bradford on 26/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MediaPlayer

class Song: MusicItem {
    
    var durationMilli : Int?
    var popularity : Int?
    var songURL : String?
    var artistName : String?
    var artistList : [Artist]?
    var songURI : String?
    var album : Album?
    
    override init(json: [String:AnyObject]) {
        
        self.durationMilli = json["duration_ms"] as? Int
        self.popularity = json["popularity"] as? Int
        self.songURL = json["playback_info"] as? String
        self.songURI = json["external_id"] as? String
        
        if let albumDict = json["album"] as? [String:AnyObject] {
            self.album = Album(json: albumDict)
        }
        
        super.init(json: json)
        
        if let artistArray = json["artists"] as? [[String:AnyObject]] {
            self.artistList = createArtistList(artistArray)
        } else if let artistDict = json["artists"] as? [String:AnyObject] {
            let arr = [artistDict]
            self.artistList = createArtistList(arr)
        }

    }
    
    init(mediaItem:MPMediaItem) {
        
        super.init()

        self.isLocal = true
        self.provider = "itunes"
        
        self.id = mediaItem.persistentID.description
        self.localID = mediaItem.persistentID

        self.name = mediaItem.title
        self.artistName = mediaItem.artist
        self.durationMilli = Int(mediaItem.playbackDuration*1000)
        self.mediaItem = mediaItem
        
    }

    func getSongURL() -> URL? {
        if let url = self.songURL {return URL(string: url)}
        else {return nil}
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
            return getLocalArtistNameString()
        }
        
        if self.getProviderType() == .soundCloud {
            
        }
        
        if self.artistList == nil {return ""}
        var nameArray : [String] = []
        for artist in self.artistList! {
            if artist.name != nil {nameArray.append(artist.name!)}
        }
        return nameArray.joined(separator: ", ")
    }
    
    func getAlbumNameString() -> String {
        
        if let album = self.album {
            if let name = album.name {return name}
            else {return ""}
        } else {return ""}
    }
    
    func getSongDurationSeconds()->Float {
        
        if let duration = self.durationMilli {
            return Float(duration)/1000.0
        } else {
            return 0.0
        }
    }
    
    func isEqualToSong(song:Song?) -> Bool {
        if song == nil {return false}
        else if (self.externalId == song!.externalId && self.localID == song!.localID && self.getProviderType() == song!.getProviderType()) {return true}
        else {return false}
    }
}
