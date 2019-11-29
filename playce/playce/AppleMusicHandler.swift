//
//  AppleMusicHandler.swift
//  playce
//
//  Created by Tys Bradford on 10/4/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit
import StoreKit

class AppleMusicHandler: NSObject {

    static let sharedHandler = AppleMusicHandler()
    static let musicTokenUpdateNotificationFailed = "APPLE_MUSIC_CONNECT_FAILED"
    
    
    //MARK: - Permissions
    func isAutherised() -> Bool {
        return SKCloudServiceController.authorizationStatus() == .authorized
    }
    
    func requestAutherisation() {
        SKCloudServiceController.requestAuthorization { (status) in
            if status == SKCloudServiceAuthorizationStatus.authorized {
                self.retrieveStorefrontID(musicToken: nil)
            }
        }
    }
    
    
    //MARK: - User
    func getUserToken(completion: ((Error?,String?)->Void)?) {
        
        if #available(iOS 11.0, *) {
            
            let devToken = APIManager.sharedInstance.appleMusicDevToken() ?? ""
            SKCloudServiceController().requestUserToken(forDeveloperToken: devToken) { (token, error) in
                completion?(error,token)
                
                if error != nil || token == nil {
                    self.sendNotificationUpdatedFailedNotification()
                } else {
                    self.retrieveStorefrontID(musicToken: token!)
                }
            }
        }
    }
    
    func retrieveStorefrontID(musicToken:String?) {
        
        SKCloudServiceController().requestStorefrontCountryCode { (storeCountryCode, error) in
            if error != nil || storeCountryCode == nil {
                self.sendNotificationUpdatedFailedNotification()
            } else {
                print("Apple store code: " + storeCountryCode!)
                self.updateAMDetailsToBackend(token: musicToken,storefrontCode: storeCountryCode!)
            }
        }
    }
    
    
    //MARK: - Convenience
    func updateAppleMusicTokensInBackground() {
        
        if self.isAutherised() {
            self.getUserToken(completion: nil)
            
        }
    }
    
    
    //MARK: - Backend
    func updateAMDetailsToBackend(token:String?, storefrontCode:String) {
        APIManager.sharedInstance.signInAppleMusic(token, storefrontCode: storefrontCode, completion: { (success) in
                if success {
                    UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_APPLE)
                    self.sendDidUpdateMusicTokenNotification()
                } else {
                    self.sendNotificationUpdatedFailedNotification()
                }
        })
 
    }
    
    //MARK: - Notifications
    func sendDidUpdateMusicTokenNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:"PROVIDER_CONNECTED"), object: nil)
    }
    
    func sendNotificationUpdatedFailedNotification() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:AppleMusicHandler.musicTokenUpdateNotificationFailed), object: nil)
    }
    
    
}
