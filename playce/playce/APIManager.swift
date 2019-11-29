//
//  APIManager.swift
//  playce
//
//  Created by Benjamin Hendricks on 5/21/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import Alamofire
import GoogleSignIn

open class APIManager: NSObject {

    static let domain: String = "http://playce-api.herokuapp.com"
    static let sharedInstance: APIManager = APIManager()
    static let SPOTIFY_CLIENT_ID_KEY = "SPOTIFY_CLIENT_ID"
    static let YOUTUBE_CLIENT_ID_KEY = "YOUTUBE_CLIENT_ID"
    static let SOUNDCLOUD_CLIENT_ID_KEY = "SOUNDCLOUD_CLIENT_ID"
    static let DEEZER_CLIENT_ID_KEY = "DEEZER_CLIENT_ID"
    static let APPLE_MUSIC_DEV_TOKEN_KEY = "APPLE_MUSIC_DEV_TOKEN_KEY"
    
    static let userIsNotAuthorizedNotification = "userIsNotAuthorizedNotification"
    static let providersWereUpdatedNotification = "providersWereUpdatedNotification"

    fileprivate var token: String {
        get
        {
            if let authToken = UserHandler.sharedInstance.getAuthKey()
            {
                return authToken
            }
            return ""
        }
    }
    fileprivate override init() {}
    
    
    // MARK: - Environment
    func getEnvironment(_ completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/sessions/environment"
        
        Alamofire.request(endpoint)
            .responseJSON {
                result in
                switch result.result {
                case .success(let value as [String:Any]):
                    if let clientID = value["spotify_client_id"] as? String {
                        UserDefaults.standard.set(clientID, forKey: APIManager.SPOTIFY_CLIENT_ID_KEY)
                    }
                    if let youtubeClientID = value["youtube_client_id"] as? String {
                        UserDefaults.standard.set(youtubeClientID, forKey: APIManager.YOUTUBE_CLIENT_ID_KEY)
//                        GIDSignIn.sharedInstance().serverClientID = youtubeClientID

                    }
                    if let soundCloudClientID = value["soundcloud_client_id"] as? String {
                        UserDefaults.standard.set(soundCloudClientID, forKey: APIManager.SOUNDCLOUD_CLIENT_ID_KEY)
                    }
                    
                    if let deezerClientID = value["deezer_client_id"] {
                        var deezerClientIDString = ""
                        if deezerClientID is String {deezerClientIDString = deezerClientID as! String}
                        if deezerClientID is Int {deezerClientIDString = String(deezerClientID as! Int)}
                        
                        UserDefaults.standard.set(deezerClientIDString, forKey:APIManager.DEEZER_CLIENT_ID_KEY)
                    }
                    
                    if let appleMusicDevToken = value["apple_music_dev_token"] as? String {
                        UserDefaults.standard.set(appleMusicDevToken, forKey:APIManager.APPLE_MUSIC_DEV_TOKEN_KEY)
                    }
                    
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                default: break
                }
        }
    }
    
    func spotifyClientID()->String{
        if let clientID = UserDefaults.standard.object(forKey: APIManager.SPOTIFY_CLIENT_ID_KEY) as? String {return clientID}
        else {return "14d415257d794e76949f6e4f8b8fa34b"}
    }

    func youtubeClientID()->String{
        if let clientID = UserDefaults.standard.object(forKey: APIManager.YOUTUBE_CLIENT_ID_KEY) as? String {return clientID}
        else {return "591484677405-ps15l6brhgpebpgvkl62pq0n6ii6416a.apps.googleusercontent.com"}
    }
    
    func soundcloudClientID()->String{
        if let clientID = UserDefaults.standard.object(forKey: APIManager.SOUNDCLOUD_CLIENT_ID_KEY) as? String {return clientID}
        else {return "lC6MV3keImpcMvGc7ZHRrgO0CxMMo5Mf"}
    }
    
    func deezerClientID()->String{
        if let deezerClientID = UserDefaults.standard.object(forKey: APIManager.DEEZER_CLIENT_ID_KEY) as? String {return deezerClientID}
        else {return "281362"}
    }
    
    func appleMusicDevToken()->String?{
        if let devToken = UserDefaults.standard.object(forKey: APIManager.APPLE_MUSIC_DEV_TOKEN_KEY) as? String {return devToken}
        else {return nil}
    }
    
    // MARK: - Authentication
    func signUp(_ name: String, email: String, password: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/users"
        let params : [String:Any] = [
            "user": [
                "email": email,
                "password": password,
                "confirmPassword": password
            ]
        ]
        
        Alamofire.request(endpoint, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil)
            .responseJSON {
                result in
                switch result.result {
                case .success(let value as [String:Any]):
                    guard let authToken = value["auth_token"] as? String else {
                        completion?(false)
                        return
                    }
                    UserHandler.sharedInstance.setAuthKey(authToken)
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                default: break
                }
        }
    }
    
    func signIn(_ email: String, password: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/sessions"
        let params : [String: AnyObject] = [
            "email": email as AnyObject,
            "password": password as AnyObject
        ]
        
        Alamofire.request(endpoint,method:.post, parameters: params, encoding: JSONEncoding.default, headers: nil)
            .responseJSON {
                result in
                switch result.result {
                case .success(let value as [String:Any]):
                    if let authToken = value["auth_token"] as? String {
                        UserHandler.sharedInstance.setAuthKey(authToken)
                        completion?(true)
                    } else {
                        completion?(false)
                    }
                case .failure(let error):
                    completion?(false)
                default: break
                }
        }
    }

    func signUpFacebook(_ token: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/sessions/facebook"
        let params: [String: AnyObject] = [
            "facebook_token": token as AnyObject
        ]
        
        Alamofire.request(endpoint, method: .post, parameters: params, encoding: JSONEncoding.default, headers: nil)
            .responseJSON {
                result in
                switch result.result {
                case .success(let value as [String:Any]):
                    if let authToken = value["auth_token"] as? String {
                        UserHandler.sharedInstance.setAuthKey(authToken)
                    }
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                default: break
                }
        }
    }
    
    func passwordReset(_ email:String, completion: ((Bool)->Void)?) {
        
        let endpoint = "\(APIManager.domain)/password_forgot"
        let params: [String: AnyObject] = [
            "email": email as AnyObject
        ]
        
        Alamofire.request(endpoint, method:.post, parameters: params, encoding: JSONEncoding.default, headers: nil)
            .responseJSON {
                result in
                switch result.result {
                case .success(let value as [String:Any]):
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                default: break
                }
        }
    }
    
    
    
    //MARK : - AUTHENTICATION
    
    
    func createAuthHeader()->[String:String] {
        let userAuthToken = UserHandler.sharedInstance.getAuthKey() ?? ""
        print(userAuthToken)
        let headers: [String: String] = [
            "Authorization": userAuthToken
        ]
        return headers
    }
    
    // MARK: - PROVIDERS
    func getAllProviders(completion: ((Bool,[ProviderObject]?)->Void)?){
        
        let endpoint = "\(APIManager.domain)/providers"
        
        Alamofire.request(endpoint, method:.get, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .validate()
            .responseJSON {
                result in
                switch result.result {
                case .success(let value):
                    
                    if let rawProviders = value as? [[String:AnyObject]] {
                        
                        var providers : [ProviderObject] = []
                        for dict in rawProviders {
                            providers.append(ProviderObject(json: dict))
                        }
                        
                        UserHandler.sharedInstance.updateConnectedProviders(providers: providers)
                        NotificationCenter.default.post(name: NSNotification.Name(APIManager.providersWereUpdatedNotification), object: nil)
                        completion?(true,providers)
                        
                    } else {
                        completion?(false,nil)
                    }
                case .failure(let error):
                    
                    //Check user is authorised
                    if let statusCode = result.response?.statusCode {
                        if statusCode == 401 {
                            NotificationCenter.default.post(name: NSNotification.Name(APIManager.userIsNotAuthorizedNotification), object: nil)
                        }
                    }
                    completion?(false,nil)
                }
        }
    }
    
    func disconnectProvider(_ provider: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/providers/\(provider)"
        
        Alamofire.request(endpoint, method:.delete, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseData {
                result in
                switch result.result {
                case .success(let value):
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    
    // MARK: - Spotify
    func signInSpotify(_ authCode: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/providers/spotify"
        let params : [String: AnyObject] = [
            "code": authCode as AnyObject,
            "callback_uri": "playce://spotify_callback" as AnyObject
        ]
        
        Alamofire.request(endpoint, method:.post, parameters: params, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseData {
                result in
                switch result.result {
                case .success(let value):
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    // MARK: - Youtube (Google)
    func signInGoogle(_ authCode: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/providers/youtube"
        let params : [String: AnyObject] = [
            "code": authCode as AnyObject,
            "callback_uri": "" as AnyObject
        ]
        
        Alamofire.request(endpoint, method:.post, parameters: params, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseData {
                result in
                switch result.result {
                case .success(let value):
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    // MARK: - Soundcloud
    func signInSoundCloud(_ authCode: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/providers/soundcloud"
        let params : [String: AnyObject] = [
            "code": authCode as AnyObject,
            "callback_uri": "http://localhost:3000/playground/oauth/callback_soundcloud" as AnyObject
        ]
        
        Alamofire.request(endpoint, method:.post, parameters: params, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseData {
                result in
                switch result.result {
                case .success(let value):
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    // MARK: - Deezer
    func signInDeezer(_ authCode: String, completion: ((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/providers/deezer_token"
        let params : [String: AnyObject] = [
            "access_token": authCode as AnyObject,
        ]
        
        Alamofire.request(endpoint, method:.post, parameters: params, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseData {
                result in
                switch result.result {
                case .success(let value):
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    // MARK: - Apple Music
    func signInAppleMusic(_ authCode:String?, storefrontCode:String, completion:((Bool)->Void)?) {
        let endpoint = "\(APIManager.domain)/providers/apple_music_token"
        let code = authCode ?? ""
        let params : [String: AnyObject] = [
            "access_token": code as AnyObject,
            "storefront" : storefrontCode as AnyObject
        ]
        
        Alamofire.request(endpoint, method:.post, parameters: params, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseData {
                result in
                switch result.result {
                case .success(let value):
                    completion?(true)
                case .failure(let error):
                    completion?(false)
                }
        }
    }
    
    
    // MARK: - My Music
    func getItemArrayFromResponse(_ response: [String:AnyObject]) -> [[String:AnyObject]]?{
        let items = response["items"] as? [[String:AnyObject]]
        if items != nil {return items}
        else {
            if let dict = response["items"] as? [String:AnyObject] {
                return dict["items"] as? [[String:AnyObject]]
            } else {return nil}
        }
    }
    
    // MARK: - Songs
    func getMySongsFromBackend(_ completion: ((Bool,[Song])->Void)?) {
        
        let endpoint = "\(APIManager.domain)/tracks"
        Alamofire.request(endpoint, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader()).responseJSON {
            response in
            switch response.result {
            case .success(let value):

                if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                    let songs = self.convertResponseToSongArray(items)
                    LibraryHandler.sharedInstance.mySongs = songs
                    completion?(true,songs)
                } else {
                    completion?(false,[])
                }
            case .failure(let error):
                completion?(false,[])
            }
        }
    }
    
    func getSongsFromBackend(_ listID: String,completion: ((Bool,[Song]?)->Void)?) {
        
        let endpoint = "\(APIManager.domain)/lists/" + listID + "/tracks"
        Alamofire.request(endpoint, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader()).responseJSON {
                response in
                switch response.result {
                case .success(let value):

                    if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                        let songs = self.convertResponseToSongArray(items)
                        completion?(true,songs)
                    } else {
                        completion?(false,[])
                    }
                case .failure(let error):
                    completion?(false,[])
                }
        }
    }
    
    func getSongsForArtist(_ artist: Artist,completion: ((Bool,[Song]?)->Void)?) {
        
        guard let artistID = artist.id else{
            completion?(false,nil)
            return
        }
        
        let endpoint = "\(APIManager.domain)/artists/" + artistID + "/tracks"
        
        Alamofire.request(endpoint, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                response in
                switch response.result {
                case .success(let value):

                    if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                        let songs = self.convertResponseToSongArray(items)
                        completion?(true,songs)
                    } else {
                        completion?(false,[])
                    }
                case .failure(let error):
                    completion?(false,[])
                }
        }
    }
    
 
    func convertResponseToSongArray(_ items: [[String:AnyObject]]) -> [Song] {
 
        var returnArray : [Song] = []
        for dict in items {
            
            let song = Song(json: dict)
            returnArray.append(song)
        }
        
        return returnArray
    }

    // MARK: - Artists
    func getArtistsFromBackend(_ completion: ((Bool,[Artist])->Void)?) {
        
        let endpoint = "\(APIManager.domain)/artists"
        Alamofire.request(endpoint, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                response in
                switch response.result {
                case .success(let value):

                    if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                        let artists = self.convertResponseToArtistArray(items)
                        LibraryHandler.sharedInstance.myArtists = artists
                        completion?(true,artists)
                    } else {
                        completion?(false,[])
                    }
                    
                case .failure(let error):
                    completion?(false,[])
                }
        }
    }
    
    
    func convertResponseToArtistArray(_ items: [[String:AnyObject]]) -> [Artist] {
        
        var returnArray : [Artist] = []
        for dict in items {
            
            let artist = Artist(json: dict)
            if artist.isValid() {
                returnArray.append(artist)
            }
        }
        
        return returnArray
    }
    
    
    // MARK: - Albums
    func getAlbumsFromBackend(_ completion: ((Bool,[Album])->Void)?) {
        
        let endpoint = "\(APIManager.domain)/lists?type=album"
        Alamofire.request(endpoint, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                response in
                switch response.result {
                case .success(let value):

                    if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                        let albums = self.convertResponseToAlbumArray(items)
                        LibraryHandler.sharedInstance.myAlbums = albums
                        completion?(true,albums)
                    } else {
                        completion?(false,[])
                    }
                    
                case .failure(let error):
                    completion?(false,[])
                }
        }
    }
    
    
    func convertResponseToAlbumArray(_ items: [[String:AnyObject]]) -> [Album] {
        
        var returnArray : [Album] = []
        for dict in items {
            
            let album = Album(json: dict)
            if album.isValid() {
                returnArray.append(album)
            }
        }
        
        return returnArray
    }

    // MARK: - Playlists
    func getPlaylistsFromBackend(_ completion: ((Bool,[Playlist]?)->Void)?) {
        
        let endpoint = "\(APIManager.domain)/lists?type=playlist"
        Alamofire.request(endpoint, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                response in
                switch response.result {
                case .success(let value):

                    if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                        let playlists = self.convertResponseToPlaylistArray(items)
                        LibraryHandler.sharedInstance.myPlaylists = playlists
                        completion?(true,playlists)
                    } else {
                        completion?(false,[])
                    }
                    
                case .failure(let error):
                    completion?(false,[])
                }
        }
    }
    
    func createPlaylist(name:String,completion:((Bool,Playlist?) -> Void)?) {
        
        let endpoint = "\(APIManager.domain)/lists"
        let paramaters = ["name":name]
        
        Alamofire.request(endpoint, method: .post, parameters: paramaters, encoding: JSONEncoding.default, headers: createAuthHeader()).validate()
            .responseJSON {
                response in
                switch response.result {
                case .success(let value):
                    if let playlistDict = value as? [String:AnyObject] {
                        completion?(true,Playlist(json: playlistDict))
                    }
                    else {
                        completion?(false,nil)
                    }
                    
                case .failure(let error):
                    completion?(false,nil)
                }
        }
    }
    
    func renamePlaylist(playlist:Playlist,name:String,completion:((Bool,Playlist?) -> Void)?) {
        
        let paramaters = ["name":name]

        let endpoint = "\(APIManager.domain)/lists/\(playlist.id ?? "")/rename"
        Alamofire.request(endpoint, method: .post, parameters: paramaters, encoding: JSONEncoding.default, headers: createAuthHeader()).validate()
            .responseJSON {
                response in
                switch response.result {
                case .success(let value):
                    
                    if let playlistDict = value as? [String:AnyObject] {
                        completion?(true,Playlist(json: playlistDict))
                    }
                    else {
                        completion?(false,nil)
                    }
                    
                case .failure(let error):
                    completion?(false,nil)
                }
        }
    }
    
    func getErrorMessageFromResponse(response:DataResponse<Any>) -> String? {
        
        if let data = response.data {
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String:AnyObject] {
                    if let errorMessage = json["error"] {return errorMessage as? String}
                    else if let errorMessage = json["errors"] {return errorMessage as? String}
                    else {return nil}
                }
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    func addTrackToPlaylist(playlist:Playlist,song:Song,completion:((Bool,Playlist?) -> Void)?) {
        
        let endpoint = "\(APIManager.domain)/lists/\(playlist.id ?? "")/add_track?track_id=\(song.externalId ?? "")&provider=\(song.getProviderType().string)"
        
        Alamofire.request(endpoint, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                response in
                switch response.result {
                case .success(let value):
                    
                    if let playlistDict = value as? [String:AnyObject] {
                        completion?(true,Playlist(json: playlistDict))
                    }
                    else {
                        completion?(false,nil)
                    }
                    
                case .failure(let error):
                    completion?(false,nil)
                }
        }
    }
    
    func removeTrackFromPlaylist(playlist:Playlist,song:Song,completion:((Bool,Playlist?) -> Void)?) {
        
        let endpoint = "\(APIManager.domain)/lists/\(playlist.id ?? "")/remove_track?track_id=\(song.externalId ?? "")"
        print(endpoint)
        
        Alamofire.request(endpoint, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader()).response { (response) in
            
            if (response.response?.statusCode == 200) {
                completion?(true,playlist)
            } else {
                completion?(false,nil)
            }
        }
    }
    
    
    func convertResponseToPlaylistArray(_ items: [[String:AnyObject]]) -> [Playlist] {
        
        var returnArray : [Playlist] = []
        for dict in items {
            
            let playlist = Playlist(json: dict)
            if playlist.isValid() {
                returnArray.append(playlist)
            }
        }
        
        return returnArray
    }
    
    
    
    // MARK: - Discovery + Search
    func getDiscoveryItems(provider:ProviderType, completion:((Bool,[(MusicItemType,String,[MusicItem])]?)->Void)?) {
        
        let providerString = self.getProviderString(type: provider)
        let endpoint = "\(APIManager.domain)/discover?provider=\(providerString)"

        Alamofire.request(endpoint, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                
                response in
                switch response.result {
                case .success(let value):
                    if let itemsDict = self.getMusicItemDictsFromResponse(response: value as? [String:AnyObject],provider: provider) {
                        
                        var returnArray : [(MusicItemType,String,[MusicItem])] = []
                        for key in itemsDict.keys {
                            
                            guard let items = itemsDict[key] else {continue}
                            guard let item = items.first else {continue}
                            let tuple = (item.getItemType(),key,items)
                            returnArray.append(tuple)
                        }
                        
                        completion?(true,returnArray)
                    } else {
                        completion?(false,nil)
                    }
                    
                case .failure(let error):
                    completion?(false,nil)
                }
        }
    }
    
    func searchForItems(searchString:String,provider:ProviderType,resultType:MusicItemType,results:Int,pageToken:String?,completion: ((Bool,[MusicItem]?)->Void)?) {
        
        let providerString = self.getProviderString(type: provider)
        let itemTypeString = self.getMusicItemTypeString(type:resultType,provider:provider)
        let searchStringEncoded = searchString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var endpoint = "\(APIManager.domain)/search?provider=\(providerString)"
        endpoint += "&section=" + itemTypeString
        endpoint += "&query=" + searchStringEncoded
        endpoint += "&limit=" + String(results)
        if pageToken != nil {endpoint += "&page=" + pageToken!}
                
        Alamofire.request(endpoint, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                
                response in
                switch response.result {
                case .success(let value):

                    if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                        
                        var results : [MusicItem] = []
                        if resultType == .track {results = self.convertResponseToSongArray(items)}
                        if resultType == .artist {results = self.convertResponseToArtistArray(items)}
                        if resultType == .album {results = self.convertResponseToAlbumArray(items)}
                        if resultType == .playlist {results = self.convertResponseToPlaylistArray(items)}
                    
                        //Need to inject provider type into MusicItem since it does not come through automatically!!!
                        self.injectProviderType(items: &results, type: provider)
                        completion?(true,results)
                    } else {
                        print(value)
                        completion?(false,[])
                    }
                    
                case .failure(let error):
                    completion?(false,[])
                }
        }
    }
    
    func searchDetails(provider:ProviderType,resultType:MusicItemType,externalID:String,results:Int,pageToken:String?,spotifyPlaylistOwner:String?,completion: ((Bool,[Song]?,String?)->Void)?) {
        
        let providerString = self.getProviderString(type: provider)
        let itemTypeString = self.getMusicItemTypeString(type:resultType,provider:provider)

        var endpoint = "\(APIManager.domain)/search/details?provider=\(providerString)"
        endpoint += "&section=" + itemTypeString
        endpoint += "&external_id=" + externalID
        endpoint += "&limit=" + String(results)
        if pageToken != nil {endpoint += "&page=" + pageToken!}
        
        if let spotifyOwner = spotifyPlaylistOwner {
            endpoint += "&playlist_owner_id=" + spotifyOwner
        }
        
        Alamofire.request(endpoint, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                
                response in
                switch response.result {
                case .success(let value):
                    if let items = self.getItemArrayFromResponse(value as! [String : AnyObject]) {
                        
                        var results : [MusicItem] = self.convertResponseToSongArray(items)
                        let nextPage = self.getNextPageTokenFromResponse(response: value as? [String:AnyObject])
                        
                        //Need to inject provider type into MusicItem since it does not come through automatically!!!
                        self.injectProviderType(items: &results, type: provider)
                        completion?(true,results as? [Song],nextPage)
                    } else {
                        completion?(false,[],nil)
                    }
                    
                case .failure:
                    completion?(false,[],nil)
                }
        }
    }
    
    
    func artistSearch(provider:ProviderType,artistID:String,completion: ((Bool,[String:[MusicItem]]?,[String]?)->Void)?) {
        
        let providerString = self.getProviderString(type: provider)
        let endpoint = "\(APIManager.domain)/artist_details"
        let params : [String: String] = ["provider":providerString,"artist_id":artistID]
        
        Alamofire.request(endpoint, method: .post, parameters: params, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                
                response in
                switch response.result {
                case .success(let value):
                    
                    //Sort order
                    let responseDict = value as? [String:AnyObject]
                    var sortOrder : [String] = []
                    if responseDict != nil {
                        sortOrder = responseDict?["display_order"] as? [String] ?? []
                    }
                    
                    //Getting a dict of dicts
                    if let items = self.getMusicItemDictsFromResponse(response: responseDict,provider:provider) {
                        completion?(true,items,sortOrder)
                    } else {
                        completion?(false,nil,sortOrder)
                    }
                    
                case .failure(let error):
                    completion?(false,nil,nil)
                }
        }
    }
    
    func artistSearchName(provider:ProviderType,artistName:String,completion: ((Bool,[String:[MusicItem]]?,[String]?)->Void)?) {
        
        let providerString = self.getProviderString(type: provider)
        let endpoint = "\(APIManager.domain)/artist_details"
        let params : [String: String] = ["provider":providerString,"artist_name":artistName]
        
        Alamofire.request(endpoint, method: .post, parameters: params, encoding: JSONEncoding.default, headers: createAuthHeader())
            .responseJSON {
                
                response in
                switch response.result {
                case .success(let value):
                    
                    //Sort order
                    let responseDict = value as? [String:AnyObject]
                    var sortOrder : [String]? = []
                    if responseDict != nil {
                        let displayOrder = responseDict?["display_order"] as? [String]
                        sortOrder = displayOrder
                    }
                    
                    //Getting a dict of dicts
                    if let items = self.getMusicItemDictsFromResponse(response: value as? [String:AnyObject],provider: provider) {
                        completion?(true,items,sortOrder)
                    } else {
                        completion?(false,nil,sortOrder)
                    }
                    
                case .failure(let error):
                    completion?(false,nil,nil)
                }
        }
    }
    
    func getMusicItemDictsFromResponse(response:[String:AnyObject]?,provider:ProviderType) -> [String:[MusicItem]]?{
        
        guard let response = response else {return nil}
        if let itemsRaw = response["items"] as? [String : AnyObject] {
            
            var finalDict : [String:[MusicItem]] = [:]
            for key in itemsRaw.keys {
                
                if let subItemsRaw = itemsRaw[key] as? [[String:AnyObject]] {
                    var musicItems = self.convertToMusicItemArray(subItemsRaw)
                    self.injectProviderType(items: &musicItems, type: provider)
                    finalDict[key] = musicItems
                }
            }
            
            return finalDict
        }
        else {return nil}
    }
    
    func convertToMusicItemArray(_ items: [[String:AnyObject]]) -> [MusicItem] {
        
        var returnArray : [MusicItem] = []
        for dict in items {
            
            var musicItem = MusicItem(json: dict)
            let type = self.getMusicItemTypeFromString(type: musicItem.type)
            
            switch type {
            case .album:
                musicItem = Album(json: dict)
                break
            case .artist:
                musicItem = Artist(json: dict)
                break
            case .track:
                musicItem = Song(json: dict)
                break
            case .playlist:
                musicItem = Playlist(json: dict)
                break
            default:
                break
            }
            
            returnArray.append(musicItem)
        }
        
        return returnArray
    }
    
    func getNextPageTokenFromResponse(response:[String:AnyObject]?) -> String? {
        guard let response = response else {return nil}
        if let page = response["next_page"] {return String(describing:page)}
        else {return nil}
    }
    
    func getProviderString(type:ProviderType) -> String {
        switch type {
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
    
    func getMusicItemTypeString(type:MusicItemType,provider:ProviderType) -> String {
        
        //Special case for YouTube
        if  (type == .track && provider == .youtube) {return "video"}
        
        switch type {
        case .track:
            return "track"
        case .album:
            return "album"
        case .artist:
            return "artist"
        case .playlist:
            return "playlist"
        default:
            return ""
        }
    }
    
    func getMusicItemTypeFromString(type:String?) -> MusicItemType {
        
        guard let type = type else {return .none}
        
        switch type {
        case "track":
            return .track
        case "video":
            return .track
        case "album":
            return .album
        case "artist":
            return .artist
        case "playlist":
            return .playlist
        default:
            return .none
        }
    }
    
    func injectProviderType(items: inout [MusicItem],type:ProviderType){
        
        for item in items {
            item.provider = self.getProviderString(type: type)
        }
    }
    
 
}
