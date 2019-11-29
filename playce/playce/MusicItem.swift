//
//  MusicItem.swift
//  playce
//
//  Created by Tys Bradford on 27/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MediaPlayer

enum ProviderType : Int {
    case none
    case spotify
    case soundCloud
    case youtube
    case iTunes
    case deezer
    case appleMusic
    
    var string: String {
        switch self {
        case .spotify:
            return "spotify"
        case .soundCloud:
            return "soundcloud"
        case .deezer:
            return "deezer"
        case .youtube:
            return "youtube"
        case .appleMusic:
            return "apple_music"
        default:
            return ""
        }
    }
}

enum MusicItemType : Int {
    case none
    case track
    case artist
    case album
    case playlist
    
    var path: String {
        switch self {
            case .track:
                    return "tracks"
            case .album, .playlist:
                    return "lists"
            case .artist:
                    return "artists"
            case .none:
                    return ""
            }
        }
    
    var value: String {
        switch self {
            case .track:
                    return "tracks"
            case .album:
                    return "albums"
            case .artist:
                    return "artists"
            case .playlist:
                    return "playlists"
            case .none:
                    return ""
            }
        }
}

class MusicItem: NSObject {

    var id : String?
    var externalId : String?
    var localID : MPMediaEntityPersistentID?

    var name : String?
    var type : String?
    var provider : String? {
        didSet {
            self.updateForAppleMusic()
        }
    }
    
    var createdAt : Date?
    var updatedAt : Date?
    var imgURL : String?
    
    var isLocal : Bool = false
    var mediaItem : MPMediaItem?

    
    
    static var sharedDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return df
    }
    
    
    init(json: [String:AnyObject]){
        
        //String parsing
        if let idRaw = json["id"] {
            self.id = String(describing: idRaw)
        }
        
        if let extID = json["external_id"] {
            self.externalId = String(describing: extID)
        }
        
        self.name = json["name"] as? String
        self.type = json["external_type"] as? String
        self.provider = json["provider"] as? String
        self.imgURL = json["image_url"] as? String
        
        let createdString = json["created_at"] as? String
        let updatedString = json["updated_at"] as? String
        
        //Dates parsing
        if let cd = createdString {
            self.createdAt = MusicItem.sharedDateFormatter.date(from: cd)
        }

        if let ud = updatedString {
            self.updatedAt = MusicItem.sharedDateFormatter.date(from: ud)
        }
        
        super.init()
        self.updateForAppleMusic()
    }
    
    override init(){
        super.init()
    }
    
    func updateForAppleMusic() {
        let imageDim = "200"
        self.imgURL = self.imgURL?.replacingOccurrences(of: "{w}", with: imageDim)
        self.imgURL = self.imgURL?.replacingOccurrences(of: "{h}", with: imageDim)
    }
    
    
    func isValid() -> Bool {
        
        //Check if there is an _id or _external_id
        if self.id == nil && self.externalId == nil {return false}
        else {return true}
    }
    
    func getProviderType() -> ProviderType {
        
        if let typeString = self.provider {
            
            switch typeString {
            case "spotify":
                return ProviderType.spotify
            case "youtube":
                return ProviderType.youtube
            case "soundcloud":
                return ProviderType.soundCloud
            case "itunes":
                return ProviderType.iTunes
            case "deezer":
                return ProviderType.deezer
            case "apple_music":
                return ProviderType.appleMusic
            default:
                return ProviderType.none
            }
        } else {
            return ProviderType.none
        }
    }
    
    func getImageURL() -> URL?{
        if self.imgURL != nil {
            
            if let encodedString = self.imgURL!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URL(string: encodedString)
            }
            else {return nil}
        }
        else {return nil}
    }
    
    //MARK: - Local Song Getters
    func getLocalImage() -> UIImage?{
        return getLocalImage(CGSize(width: 200.0, height: 200.0))
    }
    
    func getLocalImage(_ size:CGSize) -> UIImage? {
        if let img = self.mediaItem?.artwork?.image(at: size) {
            return img
        } else {
            let size = self.mediaItem?.artwork?.bounds.size
            if size == nil {return nil}
            else {return self.mediaItem?.artwork?.image(at: size!)}
        }
    }
    
    func getLocalArtistNameString()->String {
        
        if let item = self.mediaItem {
            if let artist = item.artist {
                return artist
            } else {
                return ""
            }
        } else {return ""}
    }
    
    func getItemType() -> MusicItemType {
        
        if self is Song {return .track}
        if self is Artist {return .artist}
        if self is Album {return .album}
        if self is Playlist {return .playlist}
        return .none
        
    }
    
}
