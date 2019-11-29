//
//  ItunesHandler.swift
//  playce
//
//  Created by Tys Bradford on 27/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MediaPlayer

class ItunesHandler: NSObject {

    static let sharedInstance: ItunesHandler = ItunesHandler()
    
    
    func getAllMySongs() -> [Song] {
        
        let query = MPMediaQuery.songs()
        //self.addLocalItemsOnlyToQuery(query: query)
        let mediaItems = query.items
        guard let items = mediaItems else {return []}
        
        var songs : [Song] = []
        for item in items {
            let song = Song(mediaItem: item)
            songs.append(song)
        }
        
        return songs
    }
    
    func getAllMyAlbums() -> [Album] {
        
        let query = MPMediaQuery.albums()
        guard let collections = query.collections else {return []}
        var albums : [Album] = []
        
        for collection : MPMediaItemCollection in collections {
            
            if let item = collection.representativeItem {
                let album = Album(mediaItemRep: item)
                albums.append(album)
            }
        }
        
        return albums
    }
    
    func getAllMyArtists() -> [Artist] {
        
        let query = MPMediaQuery.artists()
        guard let collections = query.collections else {return []}
        var artists : [Artist] = []
        
        for collection : MPMediaItemCollection in collections {
            
            if let item = collection.representativeItem {
                let artist = Artist(mediaItemRep: item)
                artists.append(artist)
            }
        }
        
        return artists
    }
    
    func getAllMyPlaylists() -> [Playlist] {
        
        let query = MPMediaQuery.playlists()
        guard let collections = query.collections else {return []}
        var playlists : [Playlist] = []
        
        for collection in collections {
            
            guard let mpPlaylist = collection as? MPMediaPlaylist else {continue}
            guard let item = collection.items.first else {continue}
            
            let playlist = Playlist(playlist: mpPlaylist, item:item, count:collection.count)
            playlists.append(playlist)
        }
        
        return playlists
    }
    
    func addLocalItemsOnlyToQuery(query:MPMediaQuery) {
        query.addFilterPredicate(MPMediaPropertyPredicate(value: false, forProperty: MPMediaItemPropertyIsCloudItem))
    }
    
    
    //MARK: - Child Items (Songs)
    func getSongsForArtist(item:MusicItem) -> [Song] {
        
        guard let artistName = item.name else {return []}
        let predicate = MPMediaPropertyPredicate(value: artistName, forProperty: MPMediaItemPropertyArtist)
        return self.getSongsWithPredicate(predicate: predicate)
    }
    
    func getSongsForAlbum(item:MusicItem) -> [Song] {
        guard let persistentID = item.localID else {return []}
        let predicate = MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaItemPropertyAlbumPersistentID)
        return self.getSongsWithPredicate(predicate: predicate)
    }
    
    func getSongsForPlaylist(item:MusicItem) -> [Song] {
        guard let persistentID = item.localID else {return []}
        let predicate = MPMediaPropertyPredicate(value: persistentID, forProperty: MPMediaPlaylistPropertyPersistentID)
        return self.getSongsWithPredicate(predicate: predicate)
    }
    
    func getSongsWithPredicate(predicate:MPMediaPropertyPredicate) -> [Song] {
        
        let query = MPMediaQuery.songs()
        query.addFilterPredicate(predicate)
        let mediaItems = query.items
        
        guard let items = mediaItems else {return []}
        var songs : [Song] = []
        
        for item in items {
            
            let artist = Song(mediaItem: item)
            songs.append(artist)
        }
        
        return songs
    }
    
    
    //MARK: - Convenience
    func isItunesConnected()->Bool {
        return UserDefaults.standard.bool(forKey: "ITUNES_CONNECTED")
    }
    
    func doesHaveItunesPermissions(completion: ((Bool)->Void)?) {
        
        MPMediaLibrary.requestAuthorization { (status) in
            
            guard let completion = completion else {return}
            
            switch (status) {
            case .authorized :
                completion(true)
                break
            default:
                completion(false)
                
            }
        }
    }
    
    
    
}
