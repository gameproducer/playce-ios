//
//  LibraryHandler.swift
//  playce
//
//  Created by Tys Bradford on 23/08/2017.
//  Copyright © 2017 gigster. All rights reserved.
//

import UIKit
import Alamofire


class LibraryHandler: NSObject {

    static let sharedInstance: LibraryHandler = LibraryHandler()
    
    var mySongs : [Song] = []
    var myArtists : [Artist] = []
    var myAlbums : [Album] = []
    var myPlaylists : [Playlist] = []
    
    
    override init() {
        super.init()
    }
    
    
    //MARK: - Syncronization
    
    func updateLibraryInBackground() {
        
        if UserHandler.sharedInstance.isUserLoggedIn() {
            APIManager.sharedInstance.getMySongsFromBackend(nil)
            APIManager.sharedInstance.getArtistsFromBackend(nil)
            APIManager.sharedInstance.getAlbumsFromBackend(nil)
            APIManager.sharedInstance.getPlaylistsFromBackend(nil)
        }
    }
    
    
    
    
    //MARK: - Library management
    
    func addItemToLibrary(item:MusicItem, completion: ((_ success:Bool)->Void)?) {
        
        let provider = item.getProviderType()
        let providerString = APIManager.sharedInstance.getProviderString(type: provider)
        let itemType = item.getItemType()
        
        var itemID = ""
        if item.externalId != nil {itemID = item.externalId!}
        
        var endpoint = "\(APIManager.domain)/\(itemType.path)/add?provider=\(providerString)&external_id=\(itemID)&type=\(itemType.value)"
        
        //Special case for adding Spotify playlists
        if item.isKind(of: Playlist.self) && item.getProviderType() == .spotify {
            let playlist = item as! Playlist
            if let ownerID = playlist.owner {
                endpoint += "&playlist_owner_id=\(ownerID)"
            }
        }
        
        Alamofire.request(endpoint, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: APIManager.sharedInstance.createAuthHeader()).validate()
            .responseJSON { response in
                
                switch response.result {
                case .success(let value):
                    self.addItemLocally(item: item)
                    completion?(true)
                    
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    func removeItemFromLibrary(item:MusicItem, completion: ((_ success:Bool)->Void)?) {
        
        let itemType = item.getItemType()
        var itemID = ""
        if item.id != nil {itemID = item.id!}
        else {
            if let localItem = self.getLocalItem(item: item) {
                if localItem.id != nil {itemID = localItem.id!}
            }
        }
        
        let provider = item.getProviderType()
        let providerString = APIManager.sharedInstance.getProviderString(type: provider)
        
        let endpoint = "\(APIManager.domain)/\(itemType.path)/remove?provider=\(providerString)&identifier=\(itemID)"
        Alamofire.request(endpoint, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: APIManager.sharedInstance.createAuthHeader()).validate()
            .responseJSON { response in
                
                switch response.result {
                case .success(let value):
                    self.removeItemLocally(item: item)
                    completion?(true)
                    
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    func addItemLocally(item:MusicItem) {
        let type = item.getItemType()
        switch type {
        case .track:
            self.mySongs.append(item as! Song)
            break
        case .artist:
            self.myArtists.append(item as! Artist)
            break
        case .album:
            self.myAlbums.append(item as! Album)
            break
        case .playlist:
            self.myPlaylists.append(item as! Playlist)
            break
        default:
            break
        }
    }
    
    func removeItemLocally(item:MusicItem) {
        let type = item.getItemType()
        switch type {
        case .track:
            if let index = self.mySongs.index(of: item as! Song) {
                self.mySongs.remove(at: index)
            }
            break
        case .artist:
            if let index = self.myArtists.index(of: item as! Artist) {
                self.myArtists.remove(at: index)
            }
            break
        case .album:
            if let index = self.myAlbums.index(of: item as! Album) {
                self.myAlbums.remove(at: index)
            }
            break
        case .playlist:
            if let index = self.myPlaylists.index(of: item as! Playlist) {
                self.myPlaylists.remove(at: index)
            }
            break
        default:
            break
        }

    }
    
    func getItem(item:MusicItem, in list:[MusicItem]) -> MusicItem? {
        
        for m in list {
            if let externalID = m.externalId {
                if externalID == item.externalId {return m}
            }
        }
        
        return nil;
    }
    
    func doesItemExistInLibrary(item:MusicItem) -> Bool {
        return self.getLocalItem(item: item) != nil
    }
    
    func getLocalItem(item:MusicItem) -> MusicItem? {
        let list = self.getListForItem(item: item)
        return self.getItem(item: item, in: list)
    }

    
    
    //MARK: - Utility
    
    func getListForItem(item:MusicItem) -> [MusicItem] {
        
        let type = item.getItemType()
        switch type {
        case .track:
            return self.mySongs
        case .artist:
            return self.myArtists
        case .album:
            return self.myAlbums
        case .playlist:
            return self.myPlaylists
        default:
            return []
        }
    }
    
    
    
    //MARK: - Playlists
    func createNewPlaylist(name:String) {
        
    }
    
    func renamePlaylist(playlist:Playlist,name:String) {
        
    }
    
    func getAllCustomPlaylists() {
        
    }
    
    func addTrackToPlaylist(playlist:Playlist,track:Song) {
        
    }
    
    func removeTrackFromPlaylist(playlist:Playlist,track:Song) {
        
    }
    
    
    //MARK: - Search
    static func filterItems(items:[MusicItem],searchString:String) -> [MusicItem] {
        
        if let songs = items as? [Song] {
            //Filter on name, artist, album
            return songs.filter { (item) -> Bool in
                guard let name = item.name else {return false}
                let artistName = item.getArtistNameString()
                let albumName = item.getAlbumNameString()
                return name.localizedCaseInsensitiveContains(searchString) || artistName.localizedCaseInsensitiveContains(searchString) || albumName.localizedCaseInsensitiveContains(searchString)
            }
        } else if let albums = items as? [Album] {
            //Filter on name, artist
            return albums.filter { (item) -> Bool in
                guard let name = item.name else {return false}
                let artistName = item.getArtistNameString()
                return name.localizedCaseInsensitiveContains(searchString) || artistName.localizedCaseInsensitiveContains(searchString)
            }
        } else {
            
            //Filter on name
            return items.filter { (item) -> Bool in
                guard let name = item.name else {return false}
                return name.localizedCaseInsensitiveContains(searchString)
            }
        }
    }

}
