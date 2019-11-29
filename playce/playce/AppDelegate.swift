//
//  AppDelegate.swift
//  playce
//
//  Created by Benjamin Hendricks on 5/16/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import SlideMenuControllerSwift
import AVFoundation
import Bugsee
import CallKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var slideVC : SlideMenuController?
    var playbackBarVC : PlaybackBarVC?
    var playbackFullVC : PlaybackFullVC?
    var deezerConnect : DeezerConnect?
    
    fileprivate var callObserver: CXCallObserver!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Fabric.with([Crashlytics.self])
        APIManager.sharedInstance.getEnvironment { (success) in
        }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        GIDSignIn.sharedInstance()?.signOut()
        //Google
        GIDSignIn.sharedInstance().clientID = "1038848140453-fv76ovsucu4ujcs0ikk86qnmt2fsbe91.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().serverClientID = "1038848140453-n683t8gu0cupbqnoqqmvsea4t7ubhsrl.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self

        
        if window == nil {window = UIWindow(frame: UIScreen.main.bounds)}
        guard let window = window else {return false}
        
        //if let authKey = UserHandler.sharedInstance.getAuthKey() {print("User Auth Key = " + authKey)}
        
        //Create rootVC (Slider)
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let sideMenuVC = storyboard.instantiateViewController(withIdentifier: "MenuContainerVC")
        let discoverVC = storyboard.instantiateViewController(withIdentifier: "DiscoverHomeVC")
        let navController = PLNavController()
        navController.viewControllers = [discoverVC]
        
        slideVC = SlideMenuController(mainViewController: navController, leftMenuViewController: sideMenuVC)
        SlideMenuOptions.contentViewScale = 1.0
        self.slideVC!.changeLeftViewWidth(300.0)

        UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
            window.rootViewController = self.slideVC
            }, completion: nil)
        
        slideVC?.definesPresentationContext = true
        SlideMenuOptions.simultaneousGestureRecognizers = true
        
        //Create playback VCs
        self.createPlaybackVCs()
        
        //Deezer
        self.deezerConnect = DeezerConnect.init(appId: APIManager.sharedInstance.deezerClientID(), andDelegate: self)
        DZRRequestManager.default().dzrConnect = self.deezerConnect
        
        //Get provider auth tokens (if logged in)
        if UserHandler.sharedInstance.isUserLoggedIn() {
            PlaybackHandler.sharedInstance.updateProviders()
        }
        
        //Background playback
        self.enableBackgroundAudio()
        
        //Library handler kickoff
        _ = LibraryHandler.sharedInstance
        
        //Event listeners
        NotificationCenter.default.addObserver(self, selector: #selector(songUnableToPlay(notification:)), name: Notification.Name(PlaybackHandler.playbackHandlerCouldNotPlayNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userNotAuthorized), name: Notification.Name(APIManager.userIsNotAuthorizedNotification), object: nil)
        
        //Bug tracking
        Bugsee.launch(token :"b799e44c-26b1-4a72-b5c5-46df3fa2aa88")
        
        //Call handler
        self.callObserver = CXCallObserver()
        self.callObserver.setDelegate(self, queue: nil)
        
        return true
        
    }
    
    func createPlaybackVCs(){
        
        let storyboard = UIStoryboard(name: "Playback", bundle: Bundle.main)
        playbackBarVC = storyboard.instantiateViewController(withIdentifier: "PlaybackBarVC") as? PlaybackBarVC
        playbackFullVC = storyboard.instantiateViewController(withIdentifier: "PlaybackFullVC") as? PlaybackFullVC
        
        playbackBarVC?.view.isHidden = true
        playbackFullVC?.view.isHidden = true
        
    }
    
    
    //MARK: - Background Audio
    func enableBackgroundAudio() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            // Handle setCategory failure
            print("Error enabling background audio : " + error.localizedDescription)
        }
    }
    
    //MARK: - Event Listeners
    
    //Track could not play due to no access token for provider
    @objc func songUnableToPlay(notification:Notification) {
        
        guard let rootVC = self.window?.rootViewController else {return}
        var message = "This track cannot be played right now. Please try again."
        if let song = notification.userInfo?["song"] as? Song {
            if song.getProviderType() == .spotify {
                message = "The Spotify track cannot be played. Please make sure you are a Spotify Premium subscriber to enable music streaming."
            }
        }
        
        let ac = UIAlertController(title: "Unable to play", message: message, preferredStyle: .alert)
        let actionCancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let actionRetry = UIAlertAction(title: "Retry", style: .default, handler: {
            (alert:UIAlertAction!) in
            PlaybackHandler.sharedInstance.updateProviders()
        })
        
        ac.addAction(actionCancel)
        ac.addAction(actionRetry)
        rootVC.present(ac, animated: true, completion: nil)
    }
    
    @objc func userNotAuthorized() {
        
        //Show info dialog explaining user is no longer logged in
        guard let rootVC = self.window?.rootViewController else {return}
        if let navController = rootVC as? UINavigationController {
            if navController.viewControllers.first is WelcomeScreenViewController {return}
        }
        
        let message = "It seems you have logged in on another device. Multi-device support is not currently available. Please log in again to continue."
        
        let ac = UIAlertController(title: "Unauthorized", message: message, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "OK", style: .default, handler: {
            (alert:UIAlertAction!) in
            
            //Take user back to login screen
            self.goToWelcome()
        })
        
        ac.addAction(actionOk)
        rootVC.present(ac, animated: true, completion: nil)
    }
    
    func goToWelcome() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let navController = storyboard.instantiateViewController(withIdentifier: "WelcomeScreenNavigationViewController")
        
        UIView.transition(with: self.window!, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.window!.rootViewController = navController
        }, completion: nil)
    }

    
    //MARK: - Application Lifecycle
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        //Update User Library
        LibraryHandler.sharedInstance.updateLibraryInBackground()
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        //FB Handler
        let fullUrl = url.absoluteString
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        if handled {
            return handled
        }
        
        //Spotify handler
        guard let rangeOfToken = fullUrl.range(of: "code=") else {
            return false
        }
        
        let accessCode = fullUrl.substring(from: rangeOfToken.upperBound)
        APIManager.sharedInstance.signInSpotify(accessCode) {
            success in
            if success {
                
                    PlaybackHandler.sharedInstance.updateProviders()
                
                UserDefaults.standard.set(true, forKey:UserHandler.CONNECTED_KEY_SPOTIFY)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "PROVIDER_CONNECTED"), object: nil)
            }
        }
        return true    }
}

extension AppDelegate: GIDSignInDelegate {
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
                withError error: Error!) {
        if (error == nil) {
            
            // Perform any operations on signed in user here.
            /*
            let userId = user.userID                  // For client-side use only!
            let idToken = user.authentication.idToken // Safe to send to the server
            let fullName = user.profile.name
            let givenName = user.profile.givenName
            let familyName = user.profile.familyName
            let email = user.profile.email
            */

            guard user.serverAuthCode != nil else {
                return
            }
        
            APIManager.sharedInstance.signInGoogle(user.serverAuthCode) {
                success in
                if success {
                    UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_YOUTUBE)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "PROVIDER_CONNECTED"), object: nil)
                }
            }
        } else {

        }
    }
    
    private func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!,
                withError error: NSError!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
}

extension AppDelegate: DeezerSessionDelegate {
    
    static let kDeezerCredsKeyToken = "kDeezerCredsKeyToken"
    static let kDeezerCredsKeyUserID = "kDeezerCredsKeyUserID"
    
    func deezerDidLogin() {
        
        //Inform the BE
        guard let authCode = self.deezerConnect?.accessToken else {return}
        
        APIManager.sharedInstance.signInDeezer(authCode) {
            success in
            if success {
                UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_DEEZER)
                NotificationCenter.default.post(name: Notification.Name(rawValue: "PROVIDER_CONNECTED"), object: nil)
            } else {

            }
        }
    }
    
    func deezerDidLogout() {
        self.removeDeezerAccessCredentials()
    }
    
    func storeDeezerAccessCredentials(){
        if let accessToken = self.deezerConnect?.accessToken {
            UserDefaults.standard.set(accessToken, forKey: AppDelegate.kDeezerCredsKeyToken)
        }
        if let userID = self.deezerConnect?.userId {
            UserDefaults.standard.set(userID, forKey: AppDelegate.kDeezerCredsKeyUserID)
        }
    }
    
    func loadDeezerAccessCredentials(){
        
        if let accessToken = UserDefaults.standard.string(forKey: AppDelegate.kDeezerCredsKeyToken) {
         self.deezerConnect?.accessToken = accessToken
        }
        if let userID = UserDefaults.standard.string(forKey: AppDelegate.kDeezerCredsKeyUserID) {
            self.deezerConnect?.userId = userID
        }
    }
    
    func removeDeezerAccessCredentials(){
        UserDefaults.standard.removeObject(forKey: AppDelegate.kDeezerCredsKeyToken)
        UserDefaults.standard.removeObject(forKey: AppDelegate.kDeezerCredsKeyUserID)

    }
}


//MARK: - Call Handling
extension AppDelegate: CXCallObserverDelegate {
    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        
        if call.isOutgoing == true && call.hasConnected == false {
            PlaybackHandler.sharedInstance.pausePlayback()
        }
        else if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            PlaybackHandler.sharedInstance.pausePlayback()
        }
    }
}
