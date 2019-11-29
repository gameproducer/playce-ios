//
//  PlaybackBarVC.swift
//  playce
//
//  Created by Tys Bradford on 22/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MarqueeLabel

class PlaybackBarVC: UIViewController {

    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var subtitleLabel: MarqueeLabel!
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var trackerBgView: UIView!
    @IBOutlet weak var trackerView: UIView!
    @IBOutlet weak var trackerTrailingConstraint: NSLayoutConstraint!
    
    static let barHeight : CGFloat = 45.0
    static let playbackBarShownNotification = "PLPlaybackBarShownNotification"
    static let playbackBarHiddenNotification = "PLPlaybackBarHiddenNotification"
    
    var hasBeenShown : Bool = false;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(PlaybackBarVC.barTapped))
        self.view.addGestureRecognizer(tap)
        
        //Playback listeners
        self.addPlaybackListeners()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.removePlaybackListeners()
    }
    
    override func viewDidLayoutSubviews() {
        
        //Shadowing
        self.view.layer.shadowColor = UIColor.black.cgColor;
        self.view.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        self.view.layer.shadowRadius = 2.0
        self.view.layer.shadowOpacity = 0.36
        self.view.layer.masksToBounds = false
    }

    
    //MARK: - Update View
    
    func updateView(song:Song) {
        
        titleLabel.text = song.name
        subtitleLabel.text = song.getArtistNameString()
        
        titleLabel.restartLabel()
        subtitleLabel.restartLabel()
        
        //Song image
        if let imgURL = song.getImageURL() {
            self.thumbnail.sd_setImage(with: imgURL as URL?)
        } else {
            if song.isLocal {
                self.thumbnail.image = song.getLocalImage()
            } else {
                self.thumbnail.image = UIImage(named: "music_item_placeholder")
            }
        }
        
        //Restart tracker
        self.updateTimeTracker(song: song, time: 0.0)
        
        //Youtube
        if song.getProviderType() == ProviderType.youtube {
            if !self.isPlaybackFullshowing() {
                self.addYoutubeViewToBar()
            }
        }
    }
    
    func updateTimeTracker(song:Song,time:Float){
        self.setTrailingLayout(duration: time, totalDuration: song.getSongDurationSeconds())
    }
    
    func setTrailingLayout(duration:Float, totalDuration:Float){
        
        let minTrailingConstraint = self.view.frame.size.width
        var newTrailingConstraint = minTrailingConstraint
                
        if totalDuration > 0.0{
            let percent = duration/totalDuration
            newTrailingConstraint = CGFloat(1.0 - percent) * minTrailingConstraint
        } else {newTrailingConstraint = minTrailingConstraint}
        
        if !newTrailingConstraint.isNaN {self.trackerTrailingConstraint.constant = newTrailingConstraint}
        self.view.layoutIfNeeded()
    }

    
    
    //MARK: - Playback Listeners
    
    func addPlaybackListeners(){
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidPlay(notification:)), name: Notification.Name(PlaybackHandler.playbackHandlerPlayNewNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidChangeTime(notification:)), name: Notification.Name(PlaybackHandler.playbackHandlerChangeSeekNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidPause), name: Notification.Name(PlaybackHandler.playbackHandlerPauseNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidResume), name: Notification.Name(PlaybackHandler.playbackHandlerResumeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackDidStop), name: Notification.Name(PlaybackHandler.playbackHandlerStopNotification), object: nil)
    }
    
    func removePlaybackListeners(){
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func playbackDidPlay(notification:Notification){
        
        if let song = notification.userInfo?["song"] as? Song {
            self.updateView(song: song)
            self.playPauseButton.isSelected = false
        }
    }
    
    @objc func playbackDidPause(){
        self.playPauseButton.isSelected = true
    }
    
    @objc func playbackDidResume(){
        self.playPauseButton.isSelected = false
    }
    
    @objc func playbackDidChangeTime(notification:Notification){
        
        let song = notification.userInfo?["song"] as? Song
        let time = notification.userInfo?["time"] as? Float
        if (song != nil) && (time != nil) {
            self.updateTimeTracker(song: song!, time: time!)
        }
    }
    
    @objc func playbackDidStop(){
        self.playPauseButton.isSelected = true
    }
    
    
    
    //MARK: - Interaction Handler
    @IBAction func playPauseButtonPressed(_ sender: AnyObject) {
        if self.playPauseButton.isSelected {
            PlaybackHandler.sharedInstance.resumePlayback();
        } else {
            PlaybackHandler.sharedInstance.pausePlayback();
        }
    }
    
    @objc func barTapped(){
        self.showPlaybackFull()
    }
    
    
    //MARK: - Youtube
    func addYoutubeViewToBar(){
        
        //Add to view hierachy and set autolayout constraints
        
    }
    

    
}
