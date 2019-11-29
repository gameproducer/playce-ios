//
//  UserHandler.swift
//  playce
//
//  Created by Tys Bradford on 12/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class UserHandler: NSObject {

    static let sharedInstance: UserHandler = UserHandler()
    static let kUserAuthKey : String = "USER_AUTH_KEY"
    
    static let CONNECTED_KEY_SPOTIFY = "SPOTIFY_CONNECTED"
    static let CONNECTED_KEY_SOUNDCLOUD = "SOUNDCLOUD_CONNECTED"
    static let CONNECTED_KEY_YOUTUBE = "YOUTUBE_CONNECTED"
    static let CONNECTED_KEY_DEEZER = "DEEZER_CONNECTED"
    static let CONNECTED_KEY_ITUNES = "ITUNES_CONNECTED"
    static let CONNECTED_KEY_APPLE = "APPLE_CONNECTED"
    
    
    
    func logout() {
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
    }
    
    func isUserLoggedIn() -> Bool {
        if self.getAuthKey() == nil {return false}
        else {return true}
    }
    
    func getAuthKey()->String? {
        let key = UserDefaults.standard.object(forKey: UserHandler.kUserAuthKey) as? String
        return key
    }
    
    func setAuthKey(_ authKey:String) {
        UserDefaults.standard.set(authKey, forKey: UserHandler.kUserAuthKey)
    }
    
    func getConnectedProviders() -> [ProviderType] {
        
        var connectedProviders : [ProviderType] = []
        
        if UserDefaults.standard.bool(forKey: UserHandler.CONNECTED_KEY_SPOTIFY) {
            connectedProviders.append(.spotify)
        }
        
        if UserDefaults.standard.bool(forKey: UserHandler.CONNECTED_KEY_APPLE) {
            connectedProviders.append(.appleMusic)
        }
        
        if UserDefaults.standard.bool(forKey: UserHandler.CONNECTED_KEY_DEEZER) {
            connectedProviders.append(.deezer)
        }
        
        if UserDefaults.standard.bool(forKey: UserHandler.CONNECTED_KEY_SOUNDCLOUD) {
            connectedProviders.append(.soundCloud)
        }
        
        if UserDefaults.standard.bool(forKey: UserHandler.CONNECTED_KEY_YOUTUBE) {
            connectedProviders.append(.youtube)
        }
        
        if UserDefaults.standard.bool(forKey: UserHandler.CONNECTED_KEY_ITUNES) {
            connectedProviders.append(.iTunes)
        }
        
        return connectedProviders
    }
    
    func clearConnectedProviders() {
        UserDefaults.standard.set(false, forKey: UserHandler.CONNECTED_KEY_SPOTIFY)
        UserDefaults.standard.set(false, forKey: UserHandler.CONNECTED_KEY_SOUNDCLOUD)
        UserDefaults.standard.set(false, forKey: UserHandler.CONNECTED_KEY_YOUTUBE)
        UserDefaults.standard.set(false, forKey: UserHandler.CONNECTED_KEY_DEEZER)
        UserDefaults.standard.set(false, forKey: UserHandler.CONNECTED_KEY_APPLE)
    }
    
    func updateConnectedProviders(providers:[ProviderObject]) {
        
        self.clearConnectedProviders()
        for provider in providers {
            
            if let type = provider.type {
                
                switch type {
                case .spotify:
                    UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_SPOTIFY)
                    break
                case .soundCloud:
                    UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_SOUNDCLOUD)
                    break
                case .youtube:
                    UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_YOUTUBE)
                    break
                case .deezer:
                    UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_DEEZER)
                    break
                case .appleMusic:
                    UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_APPLE)
                    break
                default:
                    
                    break
                }
            }
        }
    }
    
    func isProviderConnected(provider:ProviderType) -> Bool {
        let connected = getConnectedProviders()
        return connected.contains(provider)
    }
    
    
}
