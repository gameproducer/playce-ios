//
//  PlaybackHandler.swift
//  playce
//
//  Created by Tys Bradford on 6/10/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import Foundation
import AVFoundation
import youtube_ios_player_helper
import MediaPlayer
import GameKit
import Bugsee
class PlaybackHandler: NSObject , SPTAudioStreamingDelegate,SPTAudioStreamingPlaybackDelegate,YTPlayerViewDelegate,DZRPlayerDelegate{

    static let sharedInstance: PlaybackHandler = PlaybackHandler()
    static let playbackHandlerPlayNewNotification = "PLPlaybackHandlerPlayNewNotification"
    static let playbackHandlerPauseNotification = "PLPlaybackHandlerPauseNotification"
    static let playbackHandlerResumeNotification = "PLPlaybackHandlerResumeNotification"
    static let playbackHandlerChangeSeekNotification = "PLPlaybackHandlerChangeSeekNotification"
    static let playbackHandlerStopNotification = "PLPlaybackHandlerStopNotification"
    static let playbackHandlerCouldNotPlayNotification = "PLPlaybackHandlerCouldNotPlayNotification"
    static let playbackHandlerCouldNotPlaySpotify = "PLPlaybackHandlerCouldNotPlaySpotify"
    
    var spotifyPlayer : SPTAudioStreamingController?
    var youtubePlayer : YTPlayerView?
    var soundcloudPlayer : AVPlayer?
    var itunesPlayer : MPMusicPlayerController?
    var deezerPlayer : DZRPlayer?
    var activePlayer : AnyObject?
    
    var spotifyAccessToken : AccessToken?
    var youtubeAccessToken : AccessToken?
    var deezerAccessToken : AccessToken?
    var soundcloudAccessToken : AccessToken?
    
    var shouldUpdateSpotifyPlayer = false
    var spotifyNotPremiumAccount = false
    var durationTimer : Timer?
    
    var playbackQueue : [Song]? = []
    var shuffledQueue : [Song] = []
    var currentSong : Song?
    var playbackQueuePlayed : [Song]? = []
    
    let skipBackwardsBuffTime : Float = 3.0
    var isShuffleModeEnabled = false {
        didSet {
            if isShuffleModeEnabled {reshuffleQueue()}
        }
    }
    var isRepeatModeEnabled = false
    
    var deezerProgress : Float = 0.0
    var deezerDidFinishTrack : Bool = false
    
    
    override init() {
        super.init()
    }
    
    //MARK: - Providers
    func updateProviders() {
        
        //Apple Music
        self.createItunesPlayer()
        
        //Youtube
        self.createYoutubePlayer()
        
        //Others
        APIManager.sharedInstance.getAllProviders { (success, providers) in
            
            if success && (providers != nil){
                for provider in providers! {
                    if let providerType = provider.type {
                        if providerType == ProviderType.spotify {
                            self.spotifyAccessToken = provider.token
                        } else if providerType == ProviderType.youtube {
                            self.youtubeAccessToken = provider.token
                        } else if providerType == ProviderType.deezer {
                            self.deezerAccessToken = provider.token
                        } else if providerType == ProviderType.soundCloud {
                            self.soundcloudAccessToken = provider.token
                        }
                    }
                }
                
                //Spotify
                self.createSpotifyPlayer()
                
                //Deezer
                self.createDeezerPlayer()
                
                //Debugging
                //self.logCurrentAccessTokens()
                
                //If waiting song, play
                if self.currentSong != nil {
                    self.playSong(song: self.currentSong!)
                }
                
            }
        }
    }

    func logCurrentAccessTokens() {
        /*
        print("-------ACCESS TOKENS----------")
        print("Spotify AccessToken : " + String(describing: self.spotifyAccessToken))
        print("Youtube AccessToken : " + String(describing: self.youtubeAccessToken))
        print("Deezer AccessToken : " + String(describing: self.deezerAccessToken))
        print("Soundcloud AccessToken : " + String(describing: self.soundcloudAccessToken))
        print("------------------------------")
         */
    }
    
    
    //MARK: - Players
    func isPlayerActiveSpotify()->Bool{
        if self.activePlayer == nil {
            return false
        } else if (self.activePlayer as? SPTAudioStreamingController) != nil{
            return true
        } else {
            return false
        }
    }
    
    func isPlayerActiveItunes()->Bool{
        if self.activePlayer == nil {return false}
        else if (self.activePlayer as? MPMusicPlayerController) != nil {return true}
        else {return false}
    }
    
    func isPlayerActiveYoutube()->Bool{
        if self.activePlayer == nil {return false}
        else if (self.activePlayer as? YTPlayerView) != nil {return true}
        else {return false}
    }
    
    func isPlayerActiveDeezer()->Bool{
        if self.activePlayer == nil {return false}
        else if (self.activePlayer as? DZRPlayer) != nil {return true}
        else {return false}
    }
    
    func isPlayerActiveSoundcloud()->Bool{
        if self.activePlayer == nil {return false}
        else if (self.activePlayer as? AVPlayer) != nil {return true}
        else {return false}
    }
    
    //MARK: - Spotify Player
    func createSpotifyPlayer(){
        
        guard let accessToken = self.spotifyAccessToken?.tokenString else {return}
        let clientID = APIManager.sharedInstance.spotifyClientID()
        
        if self.spotifyPlayer != nil {
            return}
        
        if self.createSpotifySession() != nil {
            
            self.spotifyPlayer = SPTAudioStreamingController.sharedInstance()
            self.spotifyPlayer?.delegate = self
            self.spotifyPlayer?.playbackDelegate = self
            
            _ = self.createSpotifyAuth(clientID: clientID)
        
            do {
                try self.spotifyPlayer?.start(withClientId: clientID)
            } catch {
                print("Something went wrong starting Spotify Player: " + error.localizedDescription)
                Bugsee.log("Something went wrong starting Spotify Player: " + error.localizedDescription)
            }
            
            self.spotifyPlayer?.login(withAccessToken:accessToken)
        }
    }
    
    func refreshSpotifyToken(){
        
    }
    
    func createSpotifyAuth(clientID:String)->SPTAuth{
        SPTAuth.defaultInstance().clientID = clientID
        let uri = URL(string: "playce://spotify_callback")!
        let scopes = [SPTAuthStreamingScope,SPTAuthUserLibraryReadScope,SPTAuthUserFollowReadScope,SPTAuthPlaylistReadPrivateScope,SPTAuthPlaylistReadCollaborativeScope]
        
        SPTAuth.defaultInstance().redirectURL = uri
        SPTAuth.defaultInstance().requestedScopes = scopes
        SPTAuth.defaultInstance().tokenSwapURL = uri
        SPTAuth.defaultInstance().tokenRefreshURL = uri
        SPTAuth.defaultInstance().sessionUserDefaultsKey = "gr-spot-user-key";
        return SPTAuth.defaultInstance()
    }
    
    func createSpotifySession()->SPTSession? {
        
        let session = SPTSession(userName: "", accessToken: self.spotifyAccessToken?.tokenString, expirationDate: self.spotifyAccessToken?.expiryDate)
        return session
    }
    
    func isSpotifyPlayerValid()->Bool{
        return true
    }
    
    func playSpotifySong(song:Song) {
        
        guard self.spotifyPlayer != nil else {return}
        guard (self.spotifyPlayer?.loggedIn)! else {return}
        
        let songURI = song.getSongURL()
        guard songURI != nil else {return}
        self.spotifyPlayer?.playSpotifyURI(songURI?.absoluteString, startingWith: 0, startingWithPosition: 0.0, callback: { (error) in
            if error != nil {
                print("Error playing spotify track : " + (error?.localizedDescription)!)
            } else {
                self.activePlayer = self.spotifyPlayer
            }
        })
    }
    
    func stopSpotifyPlayer() {
        
        if self.isPlayerActiveSpotify() {
            self.spotifyPlayer?.setIsPlaying(false, callback: { (error) in
                if error != nil {
                    self.activePlayer = nil
                }
            })
        }
    }
    
    func pauseSpotifyPlayer(pause:Bool) {
        self.spotifyPlayer?.setIsPlaying(!pause, callback: { (error) in
            if error == nil {
                pause ? self.handlerDidPause() : self.handlerDidResume()
            }
        })
    }
    
    internal func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
    
    }
    
    internal func audioStreamingDidReconnect(_ audioStreaming: SPTAudioStreamingController!) {
        
    }
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        print("SPOTIFY RECEIVED ERROR: " + error.localizedDescription);
        self.pauseSpotifyPlayer(pause: true)
    }
    
    
    internal func audioStreamingDidLosePermission(forPlayback audioStreaming: SPTAudioStreamingController!) {
        print("SPOTIFY : DID LOSE PERMISSIONS");
    }
    
    @nonobjc internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: URL!) {
        
    }
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveMessage message: String!) {
        
    }
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        
        if !isPlaying {
            if let time = self.getCurrentSongTime() {
                if time != 0.0 {self.handlerDidPause()}
            }
        }
        else {self.handlerDidResume()}
    }
    
    @nonobjc internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: URL!) {
        
    }
    
    @nonobjc func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangeToTrack trackMetadata: [AnyHashable : Any]!) {
        print("Spotify did change to track....")
    }
    
    @nonobjc func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didFailToPlayTrack trackUri: URL!) {
        print("SPOTIFY DID FAIL TO PLAY TRACK : " + trackUri.absoluteString)
    }
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceive event: SpPlaybackEvent) {
        
        if event == SPPlaybackNotifyTrackChanged {
            
        } else if event == SPPlaybackNotifyTrackDelivered {
            
            print("Spotify track was delivered")
            //self.stopSpotifyPlayer()
            self.currentSongDidFinishPlaying()
        }
    }
    
    
    
    //MARK: - Youtube Player
    func createYoutubePlayer(){
        self.youtubePlayer = YTPlayerView()
        self.youtubePlayer?.delegate = self
        self.youtubePlayer?.isUserInteractionEnabled = false
    }
    
    func playYoutubeVideo(song:Song){
        
        print("YOUTUBE PLAYING SONG : " + String(describing: song))
        guard self.youtubePlayer != nil else {return}
        guard song.songURI != nil else {return}
        self.activePlayer = self.youtubePlayer
        let playerVars : [String:Any] = ["playsinline":1,"controls":0,"rel":0,"showinfo":0,"iv_load_policy":3,"origin":"https://www.playce.com"]
        self.youtubePlayer?.load(withVideoId: song.songURI!, playerVars: playerVars)
    }
    
    func pauseYoutubePlayer(pause:Bool){
        if pause {self.youtubePlayer?.pauseVideo()}
        else {self.youtubePlayer?.playVideo()}
        pause ? self.handlerDidPause() : self.handlerDidResume()
    }
    
    func stopYoutubePlayer(){
        self.youtubePlayer?.stopVideo()
    }

    
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        self.youtubePlayer?.playVideo()
        
        //Update the duration of the 'Song' from Youtube
        if let videoDuration = self.youtubePlayer?.duration() {
            if self.currentSong?.getProviderType() == ProviderType.youtube {
                self.currentSong?.durationMilli = Int(videoDuration*1000.0)
            }
        }
    }
    
    var youtubePlayerStatusDidBecomeUnstarted = false
    let youtubePlayerUnstartedDelayTime = 2.0
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        print("YOUTUBE DID CHANGE STATE : " + String(describing: state.rawValue))
        
        youtubePlayerStatusDidBecomeUnstarted = false

        if (state == .ended) {self.currentSongDidFinishPlaying()}
        else if state == .unstarted {
            //This means video was not available...
            //Should skip to next in this scenario
            youtubePlayerStatusDidBecomeUnstarted = true
            self.perform(#selector(skipForwardYoutubeTrack), with: nil, afterDelay: youtubePlayerUnstartedDelayTime)
        }
    }
    
    func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
        print("YOUTUBE ERROR : " + String(describing: error))
    }
    
    @objc func skipForwardYoutubeTrack() {
        if youtubePlayerStatusDidBecomeUnstarted {
            self.currentSongDidFinishPlaying()
            youtubePlayerStatusDidBecomeUnstarted = false
        }
    }

    
    //MARK: - iTunes + Apple Music Player
    func createItunesPlayer(){
        self.itunesPlayer = MPMusicPlayerController.systemMusicPlayer
        self.itunesPlayer?.prepareToPlay()
        self.itunesPlayer?.beginGeneratingPlaybackNotifications()
        self.itunesPlayer?.repeatMode = MPMusicRepeatMode.none
        
        let notificationName = Notification.Name.MPMusicPlayerControllerPlaybackStateDidChange
        let didChangePlayingNotificationName = Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange
        NotificationCenter.default.addObserver(self, selector: #selector(itunesPlaybackStateChanged), name:notificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(itunesPlayerNowPlayingDidChange), name: didChangePlayingNotificationName, object: nil)
    }
    
    func playItunesSong(song:Song) {
        guard self.itunesPlayer != nil else {return}
        guard let mediaItem = song.mediaItem else {return}
        self.activePlayer = self.itunesPlayer
        self.itunesPlayer?.setQueue(with: MPMediaItemCollection(items:[mediaItem]))
        self.itunesPlayer?.nowPlayingItem = mediaItem
        self.itunesPlayer?.prepareToPlay()
        self.itunesPlayer?.play()
    }
    
    func playAppleMusicSong(song:Song)  {
        guard self.itunesPlayer != nil else {return}
        guard let storeID = song.externalId else {return}
        self.itunesPlayer?.setQueue(with: [storeID])
        self.itunesPlayer?.prepareToPlay()
        self.itunesPlayer?.play()
        self.activePlayer = self.itunesPlayer
    }
    
    func pauseItunesPlayer(pause:Bool) {
        if pause {self.itunesPlayer?.pause()}
        else {self.itunesPlayer?.play()}
        pause ? self.handlerDidPause() : self.handlerDidResume()
    }
    
    func stopItunesPlayer(){
        self.itunesPlayer?.stop()
    }
    
    @objc func itunesPlaybackStateChanged() {
        
        print("ITUNES PLAYER STATE CHANGED");
        guard self.itunesPlayer != nil else {return}
        let trackURI = self.itunesPlayer?.nowPlayingItem?.persistentID
        
        switch self.itunesPlayer!.playbackState {
        case .stopped:
            print("STATE = STOPPED")
            
            if let currentSong = self.currentSong {
                
                if currentSong.getProviderType() == .appleMusic {
                    self.currentSongDidFinishPlaying()
                }
                else if let songURI = currentSong.localID {
                    if trackURI == songURI {
                        self.currentSongDidFinishPlaying()
                    }
                }
            }
            
            break
        case .paused:
            print("STATE = PAUSED")
            //Sometimes seeking to the end of a song causes the player to pause with a zero current playback time, or a time greater than total time.
            //This check handles this case and allows the queue to continue when this happens.
            
            guard let time = self.itunesPlayer?.currentPlaybackTime else {return}
            guard let totalTime = self.currentSong?.durationMilli else {return}
            guard let actualTotalTime = self.itunesPlayer?.nowPlayingItem?.playbackDuration else {return}
            if !self.isPlayerActiveItunes() {return}
            
            if time == 0 {
                self.currentSongDidFinishPlaying()
            }
            
            let adjustmentTollerance = 0.95
            if time >= (Double(totalTime) / 1000.0) * Double(adjustmentTollerance) {
                self.currentSongDidFinishPlaying()
            }
            break
        case .playing:
            print("STATE = PLAYING")
            self.handlerDidResume()
            break
        case .interrupted:
            print("STATE = INTERUPTED")
            break
        default:
            break
        }
    }
    
    @objc func itunesPlayerNowPlayingDidChange() {
        
    }
    
    //MARK: - Deezer Player
    func createDeezerPlayer(){
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let connection = appDelegate.deezerConnect {
            self.deezerPlayer = DZRPlayer.init(connection: connection)
            self.deezerPlayer?.delegate = self
            
            //Set deezer credentials
            if self.deezerAccessToken != nil {
                
                if let accessToken = self.deezerAccessToken?.tokenString {
                    connection.accessToken = accessToken
                }
            }
        }
    }
    
    func playDeezerSong(song:Song){
        
        //Weird bug that freezes new song play if currently playing
        //Workaround is to create new DZRPlayer instance
        if let dPlayer = self.deezerPlayer {
            if dPlayer.isPlaying() {dPlayer.stop()}
        }
        
        self.deezerPlayer = nil
        self.createDeezerPlayer()
        self.deezerProgress = 0.0

        guard let songID = song.externalId else {return}
        guard let player = self.deezerPlayer else {return}
        
        DZRTrack.object(withIdentifier: songID, requestManager: DZRRequestManager.default()) {
            (dObject, error) in
            
            self.deezerDidFinishTrack = false
            if error != nil {
                print("Error playing Deezer song : " + String(describing: error?.localizedDescription))
                return
            }
            if let dSong = dObject as? DZRTrack {
                print("Playing Deezer Track : " + dSong.description)
                self.activePlayer = self.deezerPlayer
                self.deezerProgress = 0.0
                player.play(dSong)
            }
        }
    }
    
    let kDeezerPlayerProgressFinishValue : Float = 0.995
    
    func pauseDeezerPlayer(pause:Bool){
        
        if pause {self.deezerPlayer?.pause()}
        else {self.deezerPlayer?.play()}
        
        pause ? self.handlerDidPause() : self.handlerDidResume()
    }
    
    func stopDeezerPlayer(){
        if let player = self.deezerPlayer {
            player.stop()
        }
    }
    
    func playerDidPause(_ player: DZRPlayer!) {
        print("Deezer player did pause")
        print ("Deezer player STATE = " + String(player.state.rawValue))
    }
    
    func player(_ player: DZRPlayer!, didEncounterError error: Error!) {
        print("Deezer player encountered an error : " + error.localizedDescription)
    }
    
    func player(_ player: DZRPlayer!, didPlay playedBytes: Int64, outOf totalBytes: Int64) {
        
        if totalBytes != 0 {
            let dProgress = Float(playedBytes) / Float(totalBytes)
            self.deezerProgress = dProgress
            if (dProgress >= kDeezerPlayerProgressFinishValue && !self.deezerDidFinishTrack) {
                print("Deezer player finished playing")
                self.deezerPlayerDidFinishTrack()
            }
        }
    }
    
    func player(_ player: DZRPlayer!, didStartPlaying track: DZRTrack!) {
        guard track != nil else {return}
        print("Deezer did start playing track : " + track.description)
    }
    
    func deezerPlayerDidFinishTrack(){
        self.deezerDidFinishTrack = true
        self.deezerPlayer?.stop()
        self.currentSongDidFinishPlaying()
    }
    
    
    //MARK: - Soundcloud Player
    func createSoundcloudPlayer(url:URL){
        
        print("SOUNDCLOUD PLAYING SONG : " + String(describing: url))

        if self.soundcloudPlayer != nil {self.stopSoundcloudPlayer()}
        self.soundcloudPlayer = AVPlayer(url: url)
        NotificationCenter.default.addObserver(self, selector: #selector(soundCloudPlayerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func playSoundcloudSong(song:Song) {
        
        //Need to add SC auth to playback url e.g +=?client_id=CLIENTID
        guard let url = song.getSongURL() else {return}
        let soundcloudClientID = APIManager.sharedInstance.soundcloudClientID()
        let fullURLString = url.absoluteString + "?client_id=" + soundcloudClientID
        let fullURL = URL(string: fullURLString)
        
        self.createSoundcloudPlayer(url: fullURL!)
        self.activePlayer = self.soundcloudPlayer
        self.soundcloudPlayer?.play()
    }
    
    func pauseSoundcloudPlayer(pause:Bool) {
        if let player = self.soundcloudPlayer {
            if pause {player.pause()}
            else {player.play()}
            pause ? self.handlerDidPause() : self.handlerDidResume()
        }
    }
    
    func stopSoundcloudPlayer() {
        if let player = self.soundcloudPlayer {
            player.replaceCurrentItem(with: nil)
            self.soundcloudPlayer = nil
        }
    }
    
    @objc func soundCloudPlayerDidFinishPlaying() {
        print("soundcloud did finish playing")
        self.currentSongDidFinishPlaying()
    }
    
    func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutableRawPointer) {
        if (keyPath == "status") {
            let status: AVPlayer.Status = self.soundcloudPlayer!.status
            switch (status) {
            case AVPlayerStatus.readyToPlay:
                print("---------- SOUNDCLOUD ReadyToPlay ----------")
                break
            case AVPlayerStatus.unknown, AVPlayerStatus.failed:
                print("---------- SOUNDCLOUD FAILED ----------")
                print(self.soundcloudPlayer?.error?.localizedDescription ?? "no error message")
                break
            }
        }
    }
    
    

    //MARK: - Playback Controls
    
    //Play song.
    //Return error if there is a problem with playback i.e session expired or no Spotify Premium account
    func playSong(songs:[Song],clearQueue:Bool) -> Error?{
        
        guard let song = songs.first else {return nil}
                
        if clearQueue {self.clearQueue()}
        self.addSongsToQueue(songs: songs)
        self.playSong(song: song)
        
        //Reshuffle if needed
        if self.isShuffleModeEnabled {
            self.reshuffleQueue()
        }
        
        return nil
    }
    
    func playSongFromWithinList(song:Song,list:[Song]) {
        self.clearQueue()
        self.addSongsToQueue(songs: list)
        self.playSong(song: song)
        
        //Reshuffle if needed
        if self.isShuffleModeEnabled {
            self.reshuffleQueue()
        }
    }
    
    internal func playSong(song:Song) {
        
        self.stopPlayback()
        
        if !self.checkCanPlay(song: song) {
            self.currentSong = song
            self.handlerDidStartNewSong(song: song)
            self.handlerDidPause()
            self.songWasNotAbleToPlay(song:song)
            return
        }
            
        if song.getProviderType() == ProviderType.spotify {
            self.playSpotifySong(song: song)
        } else if song.getProviderType() == ProviderType.youtube {
            self.playYoutubeVideo(song: song)
        } else if song.getProviderType() == ProviderType.iTunes {
            self.playItunesSong(song: song)
        } else if song.getProviderType() == ProviderType.deezer {
            self.playDeezerSong(song: song)
        } else if song.getProviderType() == ProviderType.soundCloud {
            self.playSoundcloudSong(song: song)
        } else if song.getProviderType() == ProviderType.appleMusic {
            self.playAppleMusicSong(song: song)
        }
    
        self.currentSong = song
        self.handlerDidStartNewSong(song: song)
        self.addSongToPlayedList(song: song)
        
        //Lock screen update
        PlaybackInfoCenterController.sharedInstance.updateNowPlayingInfoCenter()
    }
    
    func playSongFromQueue(index:Int) {
        
        guard let queue = self.getFullQueue() else {return}
        guard index < queue.count else {return}
        if let song = self.getSongInQueue(index: index) {
            self.playSong(song: song)
        }
    }
    
    func checkCanPlay(song:Song) -> Bool {
        
        if song.getProviderType() == ProviderType.spotify {
            if self.spotifyAccessToken == nil {
                 Bugsee.log("Spotify access token nil checkCanPlay")
                return false}
            if self.spotifyPlayer?.loggedIn == false {
                Bugsee.log("Spotify spotifyPLayer logged in checkCanPlay")
                return false}
        } else if song.getProviderType() == ProviderType.deezer {
            if self.deezerAccessToken == nil {return false}
        } else if song.getProviderType() == ProviderType.soundCloud {
            if self.soundcloudAccessToken == nil {return false}
        }
        
        return true
    }
    
    func songWasNotAbleToPlay(song:Song) {
        
        //Show default playback error message
        let userInfo = ["song":song]
        NotificationCenter.default.post(name: Notification.Name(PlaybackHandler.playbackHandlerCouldNotPlayNotification), object: self, userInfo:userInfo)

    }
    
    //Stop all players
    func stopPlayback(){
        
        self.stopSpotifyPlayer()
        self.stopYoutubePlayer()
        if isPlayerActiveItunes() {self.pauseItunesPlayer(pause: true)}
        self.stopDeezerPlayer()
        self.stopSoundcloudPlayer()
        self.currentSong = nil
    }
    
    func pausePlayback(){
        
        if isPlayerActiveSpotify() {
            self.pauseSpotifyPlayer(pause: true)
        } else if isPlayerActiveYoutube() {
            self.pauseYoutubePlayer(pause:true)
        } else if isPlayerActiveItunes() {
            self.pauseItunesPlayer(pause: true)
        } else if isPlayerActiveDeezer() {
            self.pauseDeezerPlayer(pause: true)
        } else if isPlayerActiveSoundcloud() {
            self.pauseSoundcloudPlayer(pause: true)
        }
    }
    
    func resumePlayback(){
        
        //Check if song is playable
        guard let song = self.currentSong else {return}
        
        if self.checkCanPlay(song:song) == false {
            self.songWasNotAbleToPlay(song: song)
            return
        }
        
        if isPlayerActiveSpotify() {
            self.pauseSpotifyPlayer(pause: false)
        } else if self.isPlayerActiveYoutube() {
            self.pauseYoutubePlayer(pause:false)
        } else if isPlayerActiveItunes() {
            self.pauseItunesPlayer(pause: false)
        } else if isPlayerActiveDeezer() {
            self.pauseDeezerPlayer(pause: false)
        } else if isPlayerActiveSoundcloud() {
            self.pauseSoundcloudPlayer(pause: false)
        } else {
            //Special case when no active player...probably when a queue has been rewound
            self.playSong(song: song)
        }
    }
    
    func skipPlaybackForward(){
        self.playNextInQueueIfNeeded()
    }
    
    func skipPlaybackBackwards(){
        
        //If current song time is less than margin time -> Go back
        //Else -> Seek to time = 0
        guard let currentSongTime = self.getCurrentSongTime() else {return}
        
        if let nextSong = self.getPreviousSongInQueue() {
            if currentSongTime < self.skipBackwardsBuffTime {
                self.playSong(song: nextSong)
            } else {
                self.seekCurrentSong(percentage: 0.0)
            }
        } else {
            self.seekCurrentSong(percentage: 0.0)
        }
    }
    
    let maxSeekPercentage : Float = 0.99
    func seekCurrentSong(percentage:Float) {
        
        //Prevent percentage being the full 100% (causes some strange behaviour)
        let adjustedPercentage = min(percentage,maxSeekPercentage)
        
        guard self.currentSong != nil else {return}
        let type = self.currentSong!.getProviderType()
        let timeOffset = self.currentSong!.getSongDurationSeconds() * adjustedPercentage
        
        switch type {
        case ProviderType.spotify :
            
            self.spotifyPlayer?.seek(to: TimeInterval(timeOffset), callback: { (error) in
                if error != nil {
                    
                }
            })
            break
        case ProviderType.youtube :
            
            self.youtubePlayer?.seek(toSeconds: timeOffset, allowSeekAhead: true)
            break
        case ProviderType.deezer :
            self.deezerPlayer?.progress = Double(adjustedPercentage)
            self.deezerDidFinishTrack = false
            break
        case ProviderType.iTunes, ProviderType.appleMusic:
            self.itunesPlayer?.currentPlaybackTime = TimeInterval(timeOffset)
            break
        case ProviderType.soundCloud :
            let time = CMTime(seconds: Double(timeOffset), preferredTimescale: (self.soundcloudPlayer?.currentTime().timescale)!)
            self.soundcloudPlayer?.seek(to: time)
            break
        default:
            break
            
        }
        
        //Update the player view
        reportCurrentSongTime()
    }
    
    
    //MARK: - Queue Handling
    func addSongToQueue(song:Song){
        
        //Remove from history if it's in there
        self.removeSongFromQueue(song: song)
        
        //Add
        self.playbackQueue?.append(song)
        self.shuffledQueue.append(song)
    }
    
    func addSongsToQueue(songs:[Song]){
        for song in songs {
            self.addSongToQueue(song: song)
        }
    }
    
    func removeSongFromQueue(song:Song) {
        guard let queue = self.getFullQueue() else {return}
        var newQueue : [Song] = []
        for qSong in queue {
            if !qSong.isEqualToSong(song: song) {
                newQueue.append(qSong)
            }
        }
        
        if self.isShuffleModeEnabled {self.shuffledQueue = newQueue}
        else {self.playbackQueue = newQueue}
    }
    
    func clearQueue() {
        self.playbackQueue = []
        self.shuffledQueue = []
    }
    
    func getNextSongInQueue()->Song? {
        if let currentIndex = self.getCurrentIndexInQueue() {
            return self.getSongInQueue(index: currentIndex+1)
        } else {return nil}
    }

    func getPreviousSongInQueue()->Song? {
        
        if let currentIndex = self.getCurrentIndexInQueue() {
            return self.getSongInQueue(index: currentIndex-1)
        } else {return nil}
    }
    
    func getSongInQueue(index:Int) -> Song? {
        guard let queue = self.getFullQueue() else {return nil}
        if index < queue.count && index >= 0 {return queue[index]}
        else {return nil}
    }
    
    func isSongInQueue(song:Song) -> Bool {
        if let _ = self.getSongInQueue(song: song) {return true}
        else {return false}
    }
    
    func getFullQueue()->[Song]?{
        return isShuffleModeEnabled ? self.shuffledQueue : self.playbackQueue
    }
    
    func getCurrentIndexInQueue()->Int?{
        
        guard let currentSong = self.currentSong else {return nil}
        guard let queue = self.getFullQueue() else {return nil}
        
        if queue.contains(currentSong) {
            if let index = queue.index(of: currentSong) {return index}
            else {return nil}
        } else {return nil}
    }
    
    func getSongInQueue(song:Song) -> Song? {
        guard let queue = self.getFullQueue() else {return nil}
        for qSong in queue {
            if qSong.isEqualToSong(song: song) {return qSong}
        }
        return nil
    }
    
    func currentSongDidFinishPlaying() {
        
        //Check if this is last song in queue & repeat if needed
        let isLast = self.isLastSongInQueue()
        if isLast {
            if self.isRepeatModeEnabled {
                _ = self.playSong(songs: self.shuffledQueue, clearQueue: true)
            } else {
                self.rewindQueueWithoutPlaying()
            }
        } else {
            self.playNextInQueueIfNeeded()
        }
    }
    
    func rewindQueueWithoutPlaying() {
        self.currentSong = self.getFullQueue()?.first
        if self.currentSong != nil {
            self.activePlayer = nil
            self.handlerDidStartNewSong(song: self.currentSong!)
            self.handlerDidPause()
        }
    }
    
    func isLastSongInQueue() -> Bool {
        
        guard let queue = self.getFullQueue() else {return true}
        if let currentIndex = self.getCurrentIndexInQueue() {
            if currentIndex >= queue.count - 1 {return true}
            else {return false}
        } else {return true}
    }
    
    func playNextInQueueIfNeeded() {
        
        //If Shuffle is enabled - handle next song differently to normal
        
        guard let currentIndex = self.getCurrentIndexInQueue() else {return}
        
        //Check if final song in queue and repeat mode enabled
        if self.isLastSongInQueue() && self.isRepeatModeEnabled {
            self.playSongFromQueue(index: 0)
            return
        }
        
        let nextIndex = currentIndex + 1
        if let _ = self.getSongInQueue(index: nextIndex) {
            self.playSongFromQueue(index: nextIndex)
        }
    }
    
    
    //MARK: - Shuffling
    func reshuffleQueue() {
        
        guard let queue = self.playbackQueue else {return}
        self.shuffledQueue = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: queue) as! [Song]
        
        if let currentIndex = self.getCurrentIndexInQueue() {
            self.moveSong(fromIndex: currentIndex, toIndex: 0)
        }
    }
    
    
    //MARK: - Shuffling (DEPRECATED)
    func resetPlayedList() {
        self.playbackQueuePlayed = []
    }
    
    func getNextSongInPlayedQueue(song:Song) -> Song?{
        guard let playedSongs = self.playbackQueuePlayed else {return nil}
        if let index = playedSongs.index(of: song) {
            if index + 1 < playedSongs.count {return playedSongs[index+1]}
            else {return nil}
        } else {
            return nil
        }
    }
    
    func getAllUnplayedSongs() -> [Song]?{
        guard let allSongs = self.playbackQueue else {return nil}
        guard let playedSongs = self.playbackQueuePlayed else {return nil}
        
        let allSongsSet = Set(allSongs)
        let playedSongsSet = Set(playedSongs)
        let unplayedSongsSet = allSongsSet.subtracting(playedSongsSet)
        return Array(unplayedSongsSet)
    }
    
    func addSongToPlayedList(song:Song) {
        guard let playedSongs = self.playbackQueuePlayed else {return}
        for playedSong in playedSongs {
            guard let playedSongID = playedSong.id else {continue}
            guard let songID = song.id else {continue}
            if songID == playedSongID {return}
        }
        self.playbackQueuePlayed?.append(song)
    }
    
    
    //MARK: - Queue Reordering
    
    func moveSong(fromIndex:Int,toIndex:Int) {
        if let song = self.getSongInQueue(index: fromIndex) {
            
            if isShuffleModeEnabled {
                self.shuffledQueue.remove(at: fromIndex)
                self.shuffledQueue.insert(song, at: toIndex)
            } else {
                self.playbackQueue?.remove(at: fromIndex)
                self.playbackQueue?.insert(song, at: toIndex)
            }
        }
    }
    
    //MARK: - Duration Timers
    func startDurationTimer(){
        
        self.stopDurationTimer();
        self.durationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(reportCurrentSongTime), userInfo: nil, repeats: true)
    }
    
    func stopDurationTimer(){
        
        if self.durationTimer != nil {
            self.durationTimer!.invalidate()
            self.durationTimer = nil
        }
    }
    
    @objc func reportCurrentSongTime(){
        guard let playbackDuration = self.getCurrentSongTime() else {return}
        guard let currentSong = self.currentSong else {return}
        self.handlerDidChangeSeekTime(song: currentSong, time: playbackDuration)
    }
    
    func getCurrentSongTime() -> Float?{
        
        var playbackDuration : Float?
        
        if self.isPlayerActiveSpotify() {
            if let duration = self.spotifyPlayer?.playbackState.position {
                playbackDuration = Float(duration)
            }
        } else if self.isPlayerActiveYoutube() {
            if let duration = self.youtubePlayer?.currentTime() {
                playbackDuration = duration
            }
            
        } else if self.isPlayerActiveItunes() {
            if let duration = self.itunesPlayer?.currentPlaybackTime {
                playbackDuration = Float(duration)
            }
        } else if self.isPlayerActiveDeezer(){
            if let _ = self.deezerPlayer?.progress {
                let trackLength = Float(self.deezerPlayer!.currentTrackDuration)
                playbackDuration = trackLength * self.deezerProgress
            }
        } else if self.isPlayerActiveSoundcloud() {
            if let duration = self.soundcloudPlayer?.currentTime().seconds {
                playbackDuration = Float(duration)
            }
        }
        
        return playbackDuration
    }
    
    
    //MARK: - Update UI
    func handlerDidPause(){
        self.stopDurationTimer()
        NotificationCenter.default.post(name: Notification.Name(PlaybackHandler.playbackHandlerPauseNotification), object: self)
    }
    
    func handlerDidResume(){
        self.startDurationTimer()
        NotificationCenter.default.post(name: Notification.Name(PlaybackHandler.playbackHandlerResumeNotification), object: self)
    }
    
    func handlerDidStartNewSong(song:Song){
        
        self.startDurationTimer()
        let userInfo = ["song":song]
        NotificationCenter.default.post(name:  Notification.Name(PlaybackHandler.playbackHandlerPlayNewNotification), object: self, userInfo: userInfo)
    }
    
    func handlerDidChangeSeekTime(song:Song,time:Float) {
        let userInfo = ["song":song,"time":time] as [String : Any]
        NotificationCenter.default.post(name:  Notification.Name(PlaybackHandler.playbackHandlerChangeSeekNotification), object: self, userInfo: userInfo)
    }
    
    func handlerDidStop(){
        self.stopDurationTimer()
        NotificationCenter.default.post(name: Notification.Name(PlaybackHandler.playbackHandlerStopNotification), object: self)
    }
    

}
