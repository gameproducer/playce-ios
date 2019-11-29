//
//  ChooseProviderViewController.swift
//  playce
//
//  Created by Benjamin Hendricks on 5/25/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift
import GoogleSignIn;


class ChooseProviderViewController: UIViewController {

    let providers: [Provider] = [.Apple, .Spotify, .Youtube, .SoundCloud, .Deezer, .iTunesLibrary]
    var connectedProviders: [Provider] = []
    var customLoadIndicator : CustomLoadIndicator?
    var isFromSettings : Bool = false

    @IBOutlet weak var providerTableView: UITableView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadProviders()
        self.customLoadIndicator = CustomLoadIndicator(parentView: self.view)

        NotificationCenter.default.addObserver(self, selector: #selector(ChooseProviderViewController.reloadProviders), name: NSNotification.Name(rawValue: "PROVIDER_CONNECTED"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChooseProviderViewController.appleMusicConnectFailed), name: NSNotification.Name(rawValue: AppleMusicHandler.musicTokenUpdateNotificationFailed), object: nil)

        
        self.retrieveConnectProvidersFromBackend();
        if self.isFromSettings {self.doneButton.isHidden = true}
        else {self.backButton.isHidden = true}
        
    }
    
    @objc func reloadProviders() {
        
        connectedProviders.removeAll()
        
        if UserHandler.sharedInstance.isProviderConnected(provider: .spotify) {
            connectedProviders.append(.Spotify)
        }
        
        if UserHandler.sharedInstance.isProviderConnected(provider: .youtube) {
            connectedProviders.append(.Youtube)
        }
        
        if UserHandler.sharedInstance.isProviderConnected(provider: .soundCloud) {
            connectedProviders.append(.SoundCloud)
        }

        if UserHandler.sharedInstance.isProviderConnected(provider: .iTunes) {
            connectedProviders.append(.iTunesLibrary)
        }
        
        if UserHandler.sharedInstance.isProviderConnected(provider: .deezer) {
            connectedProviders.append(.Deezer)
        }
        
        if UserHandler.sharedInstance.isProviderConnected(provider: .appleMusic) {
            connectedProviders.append(.Apple)
        }
        
    
        providerTableView.reloadData()
    }
    
    func retrieveConnectProvidersFromBackend(){
        
        APIManager.sharedInstance.getAllProviders { (success, providers) in
            if success && (providers != nil) {
                for provider in providers! {
                    if let type = provider.type {
                        switch type {
                        case .soundCloud:
                            UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_SOUNDCLOUD)
                            break
                        case .spotify:
                            UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_SPOTIFY)
                            break
                        case .youtube:
                            UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_YOUTUBE)
                            break
                        case .iTunes:
                            UserDefaults.standard.set(true, forKey: UserHandler.CONNECTED_KEY_ITUNES)
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
                self.reloadProviders()
            }
        }
    }
}

extension ChooseProviderViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return providers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: ChooseProviderTableViewCell.reuseId, for: indexPath) as? ChooseProviderTableViewCell {
         
            let provider = providers[(indexPath as NSIndexPath).row]
            cell.setup(provider, isConnected: connectedProviders.contains(provider))
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch providers[(indexPath as NSIndexPath).row] {
        case .Spotify where !connectedProviders.contains(.Spotify):
            signInSpotify()
        case .Spotify:
            disconnectSpotify()
        case .Youtube where !connectedProviders.contains(.Youtube):
            signInYoutube()
        case .Youtube:
            disconnectYoutube()
        case .iTunesLibrary where !connectedProviders.contains(.iTunesLibrary):
            signInItunes()
        case .iTunesLibrary:
            disconnectItunes()
        case .SoundCloud where !connectedProviders.contains(.SoundCloud):
            signInSoundCloud()
        case .SoundCloud:
            disconnectSoundCloud()
        case .Deezer where !connectedProviders.contains(.Deezer):
            connectDeezer()
        case .Deezer:
            disconnectDeezer()
        case .Apple where !connectedProviders.contains(.Apple):
            connectAppleMusic()
        case .Apple:
            disconnectAppleMusic()
        }
    }
    
    
    //MARK: - SoundCloud
    func disconnectSoundCloud() {
        self.customLoadIndicator?.startAnimating()
        APIManager.sharedInstance.disconnectProvider("soundcloud", completion: {
            success in
            self.customLoadIndicator?.stopAnimating()
            if success {
                if let index = self.connectedProviders.index(of: .SoundCloud) {
                    self.connectedProviders.remove(at: index)
                    UserDefaults.standard.removeObject(forKey: UserHandler.CONNECTED_KEY_SOUNDCLOUD)
                    self.providerTableView.reloadData()
                }
            }
        })
    }
    
    func signInSoundCloud() {
        
        let clientID = APIManager.sharedInstance.soundcloudClientID()
        let responseType = "code"
        let scope = "non-expiring"
        let display = "popup"
        //let redirectURL = "playce://soundcloud.callback".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        let redirectURL = "http://localhost:3000/playground/oauth/callback_soundcloud".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        
        var scURL = "https://www.soundcloud.com/connect?client_id=" + clientID
        scURL.append("&redirect_uri=" + redirectURL!)
        scURL.append("&response_type=" + responseType)
        scURL.append("&scope=" + scope)
        scURL.append("&display=" + display)
        
        guard let url = URL(string: scURL) else {
            return
        }
        
        //UIApplication.shared.open(url, options: [:], completionHandler: nil)
        self.showSoundcloudLoginWebview(url: url)
    }
    
    
    //MARK: - Itunes
    func signInItunes() {
        UserDefaults.standard.set(true, forKey: "ITUNES_CONNECTED")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PROVIDER_CONNECTED"), object: nil)
    }
 
    func disconnectItunes() {
        if let index = self.connectedProviders.index(of: .iTunesLibrary) {
            self.connectedProviders.remove(at: index)
            UserDefaults.standard.removeObject(forKey: UserHandler.CONNECTED_KEY_ITUNES)
            self.providerTableView.reloadData()
        }
    }
    
    //MARK: - Spotify
    func signInSpotify() {
        
        let clientID = APIManager.sharedInstance.spotifyClientID()
        let spotAuth = PlaybackHandler.sharedInstance.createSpotifyAuth(clientID: clientID)
        
        UIApplication.shared.openURL(SPTAuth.loginURL(forClientId: clientID, withRedirectURL: spotAuth.redirectURL, scopes: spotAuth.requestedScopes, responseType: "code"))
    }
    
    func disconnectSpotify() {
        self.customLoadIndicator?.startAnimating()
        APIManager.sharedInstance.disconnectProvider("spotify", completion: {
            success in
            self.customLoadIndicator?.stopAnimating()
            if success {
                if let index = self.connectedProviders.index(of: .Spotify) {
                    self.connectedProviders.remove(at: index)
                    UserDefaults.standard.removeObject(forKey: UserHandler.CONNECTED_KEY_SPOTIFY)
                    self.providerTableView.reloadData()
                }
            }
        })
    }
    
    //MARK: - Deezer
    func connectDeezer(){
        
        let permissions = [DeezerConnectPermissionBasicAccess,DeezerConnectPermissionOfflineAccess]
        getAppDelegate().deezerConnect?.authorize(permissions)
    }
    
    func disconnectDeezer(){
        self.customLoadIndicator?.startAnimating()
        APIManager.sharedInstance.disconnectProvider("deezer", completion: {
            success in
            self.customLoadIndicator?.stopAnimating()
            if success {
                if let index = self.connectedProviders.index(of: .Deezer) {
                    self.connectedProviders.remove(at: index)
                    UserDefaults.standard.removeObject(forKey: UserHandler.CONNECTED_KEY_DEEZER)
                    self.providerTableView.reloadData()
                }
            }
        })
    }
    
    
    //MARK: - Apple Music
    func connectAppleMusic() {
        
        if AppleMusicHandler.sharedHandler.isAutherised() {
            AppleMusicHandler.sharedHandler.retrieveStorefrontID(musicToken: nil)
        } else {
            AppleMusicHandler.sharedHandler.requestAutherisation()
        }
    }
    
    func disconnectAppleMusic() {
        
        self.customLoadIndicator?.startAnimating()
        APIManager.sharedInstance.disconnectProvider("apple_music", completion: {
            success in
            self.customLoadIndicator?.stopAnimating()
            if success {
                if let index = self.connectedProviders.index(of: .Apple) {
                    self.connectedProviders.remove(at: index)
                    UserDefaults.standard.removeObject(forKey: UserHandler.CONNECTED_KEY_APPLE)
                    self.providerTableView.reloadData()
                }
            }
        })
    }
    
    @objc func appleMusicConnectFailed() {
        
        let ac = UIAlertController(title: "Uh oh", message: "There was an error connecting with the Apple Music API. Please try again later", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(okAction)
        self.present(ac, animated: true, completion: nil)
    }
    

    
    
    //MARK: - Button Handlers
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        if let nav = navigationController {
            if self.isFromSettings {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
            }
            nav.popToRootViewController(animated: true)
        } else {
            guard let window = UIApplication.shared.keyWindow else {
                return
            }
            
            let slideVC = self.getSliderVC()
            UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                window.rootViewController = slideVC
                }, completion: nil)
        }
    }
    
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        //Update players
        PlaybackHandler.sharedInstance.updateProviders()
        
        if self.isFromSettings == true {
            _ = self.navigationController?.popViewController(animated: true)
            self.navigationController?.setNavigationBarHidden(false, animated: false)
        } else {
            let slideVC = self.getSliderVC()
            UIView.transition(with: window, duration: 0.5, options: .transitionFlipFromLeft, animations: {
                window.rootViewController = slideVC
            }, completion: nil)
        }
    }
}

extension ChooseProviderViewController: GIDSignInUIDelegate,GIDSignInDelegate {
    
    //MARK: - Youtube
    func disconnectYoutube() {
        self.customLoadIndicator?.startAnimating()
        APIManager.sharedInstance.disconnectProvider("youtube", completion: {
            success in
            self.customLoadIndicator?.stopAnimating()
            if success {
                if let index = self.connectedProviders.index(of: .Youtube) {
                    self.connectedProviders.remove(at: index)
                    UserDefaults.standard.removeObject(forKey: UserHandler.CONNECTED_KEY_YOUTUBE)
                    self.providerTableView.reloadData()
                }
            }
        })
    }
    
    func signInYoutube() {
        
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/youtube"]
        GIDSignIn.sharedInstance().signIn()
    }
    
    //MARK: - Google Delegate
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        dismiss(animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {

        if (error == nil) {
                        
            guard user.serverAuthCode != nil else {return}
            APIManager.sharedInstance.signInGoogle(user.serverAuthCode) {
                success in
                if success {
                    UserDefaults.standard.set(true, forKey: "YOUTUBE_CONNECTED")
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "PROVIDER_CONNECTED"), object: nil)
                }
            }
        } else {

        }
    }
}

extension ChooseProviderViewController : UIWebViewDelegate {
    
    func showSoundcloudLoginWebview(url:URL) {
        
        let vc = UIViewController()
        let navController = UINavigationController(rootViewController: vc)
        let webview = UIWebView(frame: self.view.bounds)
        
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(closeSoundCloudLogin))
        vc.navigationItem.leftBarButtonItem?.tintColor = PLStyle.greenColor()
        webview.delegate = self
        webview.loadRequest(URLRequest(url: url))
        vc.view.addSubview(webview)
        vc.view.frame = self.view.bounds
        
        self.present(navController, animated: true, completion: nil)
        
    }
    
    func didGetSoundCloudOAuthCode(accessCode:String){
        APIManager.sharedInstance.signInSoundCloud(accessCode) {
            success in
            if success {
                UserDefaults.standard.set(true, forKey: "SOUNDCLOUD_CONNECTED")
                NotificationCenter.default.post(name: Notification.Name(rawValue: "PROVIDER_CONNECTED"), object: nil)
            }
        }
    }
    
    @objc func closeSoundCloudLogin() {
        self.closeSoundCloudLoginWithError(wasError: false)
    }
    
    func closeSoundCloudLoginWithError(wasError:Bool) {
        self.dismiss(animated: true, completion: {
            if wasError {self.showSoundcloudLoginError()}
        })
    }
    
    func showSoundcloudLoginError() {
        let ac = UIAlertController(title: "Uh oh", message: "There was an error connecting with the SoundCloud API. Please try again later", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(okAction)
        self.present(ac, animated: true, completion: nil)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        
        guard let urlString = request.url?.absoluteString else {return true}
        
        if urlString.contains("http://localhost") {

            let split = urlString.components(separatedBy: "code=")
            if split.count == 2 {
                var code = split[1]
                code = code.replacingOccurrences(of: "#", with: "")
                
                self.didGetSoundCloudOAuthCode(accessCode: code)
                self.closeSoundCloudLoginWithError(wasError: false)
                return false
            } else {
                self.closeSoundCloudLoginWithError(wasError: true)
                return false
            }
        }
        
        return true
    }
}
