//
//  Provider.swift
//  playce
//
//  Created by Tys Bradford on 12/10/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import Foundation


class ProviderObject : NSObject {


    var type : ProviderType?
    var token : AccessToken?
    var createdAt : Date?
    var updatedAt : Date?
    
    static var sharedDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return df
    }
    
    init(json: [String:AnyObject]){
    
        
        //Dates
        let createdString = json["created_at"] as? String
        let updatedString = json["updated_at"] as? String
        if let cd = createdString {
            self.createdAt = ProviderObject.sharedDateFormatter.date(from: cd)
        }
        
        if let ud = updatedString {
            self.updatedAt = ProviderObject.sharedDateFormatter.date(from: ud)
        }
        
        super.init()

        self.type = self.getProviderType(name: json["provider"] as! String?)

        if let params = json["params"] as? [String:AnyObject] {
            self.token = AccessToken(json: params)
        }
        
        if let params = json["params"] as? String {
            
            //Transform string to Dictionary
            guard let paramsData = params.data(using: String.Encoding.utf8) else {return}
            
            let paramsJSON = try? JSONSerialization.jsonObject(with: paramsData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:AnyObject]
            
            if paramsJSON != nil {
                self.token = AccessToken(json: paramsJSON!)
            }
        }
    }


    
    override init(){
        super.init()
    }
    
    func getProviderType(name:String?) -> ProviderType {
        
        if let typeString = name {
            
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
    
    public class func getProviderNameFromType(provider:ProviderType)->String {
        switch provider {
        case .none:
            return ""
        case .spotify:
            return "Spotify"
        case .soundCloud:
            return "SoundCloud"
        case .iTunes:
            return "iTunes"
        case .youtube:
            return "YouTube"
        case .deezer:
            return "Deezer"
        case .appleMusic:
            return "Apple Music"
        }
    }
    
    
    
}
