//
//  AccessToken.swift
//  playce
//
//  Created by Tys Bradford on 12/10/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import Foundation


class AccessToken : NSObject {

    var tokenString : String?
    var tokenType : String?
    var refreshToken : String?
    var idToken : String?
    var expiryDate : Date?
    var provider : ProviderObject?
    
    
    static var sharedDateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return df
    }
    
    init(json: [String:AnyObject]){
        
        self.tokenString = json["access_token"] as! String?
        self.tokenType = json["token_type"] as! String?
        self.refreshToken = json["refresh_token"] as? String
        self.idToken = json["id_token"] as! String?
        
        super.init()

        //Dates parsing
        let timeInterval = json["expires_in"] as? Int
        if (timeInterval != nil) && (provider != nil) {
            
            if let date = provider!.updatedAt {
                expiryDate = date.addingTimeInterval(TimeInterval(timeInterval!))
            }
        }
    }
    
    override var description: String {
        return "Token : \(tokenString) \nRefreshToken : \(refreshToken) \nProvider : \(provider)"
    }

}
