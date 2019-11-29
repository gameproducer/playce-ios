//
//  PlaybackFullVC.swift
//  playce
//
//  Created by Tys Bradford on 22/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import iCarousel
import MarqueeLabel
import youtube_ios_player_helper


class PlaybackFullVC: UIViewController,iCarouselDataSource, iCarouselDelegate {

    
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var bgBlurImage: UIImageView!
    @IBOutlet weak var bgView: UIImageView!
    @IBOutlet weak var artScrollView: UIScrollView!
    
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var trackNameLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    
    @IBOutlet weak var scrubber: UISlider!
    
    @IBOutlet weak var timerTotalLabel: UILabel!
    @IBOutlet weak var timerRemainLabel: UILabel!
    
    
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var loopButton: UIButton!
    
    var coverArtQueueVC : CoverArtQueueVC!
    @IBOutlet weak var carousel: iCarousel!
    var youtubeView : YTPlayerView?
    var isScrubbing : Bool = false
    
    var queueTableVC : QueueTableVC!
    var shouldHideStatusBar : Bool = false
    var currentSong : Song?
    var optionsVC : MusicPopupContainerVC?
    
    @IBOutlet weak var queueButton: UIButton!
    @IBOutlet weak var pauseButtonBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Custom UI
        self.scrubber.setThumbImage(UIImage(named:"playback_scrubber_control"), for: UIControl.State.normal)
        
        //Listeners
        self.addPlaybackListeners()
        
        //Blur View
        let blur = UIBlurEffect(style: UIBlurEffect.Style.light)
        self.blurView.effect = blur
        self.bgView.backgroundColor = UIColor.clear
        self.blurView.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.white
        
        //Notification listeners
        self.addPlaybackListeners()
        
        //Carousel
        self.carousel.delegate = self
        self.carousel.dataSource = self
        self.carousel.type = .rotary
        
        
        //Custom fonts (not being set in Storyboard for some reason)
        self.trackNameLabel.font = UIFont(name: ".SFUIText-Semibold", size: 22.0)
        self.artistLabel.font = UIFont(name: ".SFUIText", size: 16.0)
        self.sourceLabel.font = UIFont(name: ".SFUIText-Bold", size: 13.0)
        
        //Scrubbing
        self.scrubber.addTarget(self, action: #selector(scrubbingDidStart), for: UIControl.Event.touchDown)
        self.scrubber.addTarget(self, action: #selector(scrubbingDidStop), for: [.touchUpInside,.touchUpOutside])
        self.scrubber.addTarget(self, action: #selector(scrubberWasMoved), for: UIControl.Event.touchDragInside)
        
        //Queue View
        self.addQueueView()
        
        //Small screen adjustment
        let screenHeight = UIScreen.main.bounds.height
        if screenHeight <= 568.0 {
            self.adjustViewForSmallScreen()
        }
        
        self.modalPresentationCapturesStatusBarAppearance = true

    }
    
    override var prefersStatusBarHidden : Bool {
        return self.shouldHideStatusBar
    }
    
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .slide
    }
    
    func adjustViewForSmallScreen() {
        self.pauseButtonBottomConstraint.constant -= 20.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        self.removePlaybackListeners()
    }
    
    func addYouTubePlayerView() {
        
        if let youtubeView = PlaybackHandler.sharedInstance.youtubePlayer {
            self.youtubeView = youtubeView
            
            //Add view
            self.youtubeView?.removeFromSuperview()
            self.view.addSubview(youtubeView)
            self.youtubeView?.frame = CGRect.init(x: 15.0, y: 200.0, width: 320.0, height: 250.0)

            //Add constraints
            self.addYouTubePlayerConstraints()
        }
    }
    
    func addYouTubePlayerConstraints() {
        
        guard let youtubeView = self.youtubeView else {return}
        youtubeView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addConstraint(NSLayoutConstraint.init(item: youtubeView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 15.0))
        self.view.addConstraint(NSLayoutConstraint.init(item: youtubeView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: -15.0))
        self.view.addConstraint(NSLayoutConstraint.init(item: youtubeView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.carousel, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0.0))
        self.view.addConstraint(NSLayoutConstraint.init(item: youtubeView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.carousel, attribute: NSLayoutConstraint.Attribute.height, multiplier: 0.64, constant: 0.0))
    }
    
    
    func addQueueView() {
        
        self.queueTableVC = self.storyboard?.instantiateViewController(withIdentifier: "QueueTableVC") as! QueueTableVC
        self.addChild(self.queueTableVC)
        self.queueTableVC.didMove(toParent: self)
        
        let tableView = self.queueTableVC.view!
        tableView.isHidden = true
        self.view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addConstraint(NSLayoutConstraint.init(item: tableView, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0.0))
        self.view.addConstraint(NSLayoutConstraint.init(item: tableView, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0.0))
        self.view.addConstraint(NSLayoutConstraint.init(item: tableView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.carousel, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1.0, constant: 0.0))
        self.view.addConstraint(NSLayoutConstraint.init(item: tableView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.carousel, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: 0.0))
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let ytv = self.youtubeView {
            ytv.layer.shadowColor = UIColor.black.cgColor;
            ytv.layer.shadowOffset = CGSize(width: 0.0, height: 1)
            ytv.layer.shadowRadius = 2.0
            ytv.layer.shadowOpacity = 0.36
            ytv.layer.masksToBounds = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        self.addYouTubePlayerView()
        self.queueTableVC.updateView()
        self.updateCarousel()
        
        self.shouldHideStatusBar = true
        UIView.animate(withDuration: 0.25, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.shouldHideStatusBar = false
    }
    
    
    //MARK: - Update View
    
    func updateView(song:Song) {
        
        currentSong = song
        trackNameLabel.text = song.name
        artistLabel.text = song.getArtistNameString()
        
        trackNameLabel.resetLabel()
        artistLabel.resetLabel()
        
        //Album
        albumLabel.text = song.getAlbumNameString()

        //Platform
        switch song.getProviderType() {
        case .spotify:
            sourceLabel.text = "PLAYING FROM SPOTIFY"
        case .youtube:
            sourceLabel.text = "PLAYING FROM YOUTUBE"
        case .iTunes:
            sourceLabel.text = "PLAYING FROM APPLE"
        case .deezer:
            sourceLabel.text = "PLAYING FROM DEEZER"
        case .soundCloud:
            sourceLabel.text = "PLAYING FROM SOUNDCLOUD"
        case .appleMusic:
            sourceLabel.text = "PLAYING FROM APPLE MUSIC"
        default:
            sourceLabel.text = "PLAYING"
        }
        
        //Restart tracker
        self.updateTimeTracker(song: song, time: 0.0)
        
        //Update cover art queue
        self.updateCarousel()
        
        //Update BG blur
        if let imgURL = song.getImageURL() {
            self.bgBlurImage.sd_setImage(with: imgURL as URL?)
        } else {
            if song.isLocal {
                self.bgBlurImage.image = song.getLocalImage()
            }
        }
        
        //Playback Settings
        self.updatePlaybackSettingsUI()
        
        //Main view
        if song.getProviderType() == ProviderType.youtube {
            self.showYoutubePlayer()
        } else {
            self.showCarousel()
        }
        
        //Add button
        updateAddButton()
    }
    
    func updatePlaybackSettingsUI() {
        self.shuffleButton.isSelected = PlaybackHandler.sharedInstance.isShuffleModeEnabled
        self.loopButton.isSelected = PlaybackHandler.sharedInstance.isRepeatModeEnabled
    }
    
    func updateTimeTracker(song:Song,time:Float){
        
        guard !time.isNaN else {return}
        guard !time.isInfinite else {return}
        guard !self.isScrubbing else {return}
        
        let totalDuration = song.getSongDurationSeconds()
        let timeRemaining = totalDuration - time
        
        if totalDuration == 0.0 {
            self.scrubber.value = 0.0
        } else {
            
            //Scrubber
            let percent = time/totalDuration
            self.scrubber.setValue(percent, animated: true)
            
            //Time labels
            self.updateTimeLabels(time: time, timeRemaining: timeRemaining)
        }
    }
    
    func updateTimeLabels(time:Float,timeRemaining:Float){
        
        //Time labels
        let minutes = Int(time / Float(60.0))
        let seconds = Int(time.truncatingRemainder(dividingBy: Float(60.0)))
        
        let minutesRemain = Int(timeRemaining / Float(60.0))
        let secondsRemain = Int(timeRemaining.truncatingRemainder(dividingBy: Float(60.0)))
        
        if (time > 0.0){
            timerTotalLabel.text = String(format: "%02d:%02d", minutes,seconds)
            timerRemainLabel.text =  String(format: "%02d:%02d", minutesRemain,secondsRemain)
        } else {
            timerTotalLabel.text = "00:00"
            timerRemainLabel.text =  String(format: "%02d:%02d", minutesRemain,secondsRemain)
        }
    }
    
    func showCarousel(){
        self.carousel.isHidden = false
        self.youtubeView?.isHidden = true
    }
    
    func showYoutubePlayer(){

        self.hideQueueView()
        self.carousel.isHidden = true
        
        if self.youtubeView == nil {
            self.addYouTubePlayerView()
        }
        self.youtubeView?.isHidden = false
    }
    
    func showQueueView() {
        self.queueTableVC.updateView()
        self.queueTableVC.view.isHidden = false
        self.bgView.backgroundColor = UIColor.white
        self.view.bringSubviewToFront(self.queueTableVC.view)
        self.queueButton.isSelected = true
    }
    
    func hideQueueView() {
        self.queueTableVC.view.isHidden = true
        self.bgView.backgroundColor = UIColor.clear
        self.queueButton.isSelected = false
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
        
        self.queueTableVC.updateView()
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
        if let song = PlaybackHandler.sharedInstance.currentSong {
            self.updateTimeTracker(song: song, time: 0.0)
        }
    }
    
    
    
    //MARK: - Button Handlers
    @IBAction func closeButtonPressed(_ sender: AnyObject) {
        closePlayer()
    }
    
    func closePlayer() {
        
        let isPaused = self.playPauseButton.isSelected
        self.dismiss(animated: true, completion:{
            
            //Workaround for weird YouTube bug that pauses player on dismiss
            if PlaybackHandler.sharedInstance.isPlayerActiveYoutube() {
                if PlaybackHandler.sharedInstance.getCurrentSongTime() != 0.0 && !isPaused {PlaybackHandler.sharedInstance.pauseYoutubePlayer(pause: false)}
            }
            
            //TODO: Find more permanent solution to this
            //Fix for iOS 11 update weird UI bug
            guard let mainVC = self.getMainVCView() else {return}
            let playbackVC = self.getPlaybackBar()
            mainVC.bringSubviewToFront(playbackVC.view!)
        })
    }
    
    @IBAction func queueButtonPressed(_ sender: AnyObject) {
        if self.queueTableVC.view.isHidden {
            self.showQueueView()
        } else {
            self.hideQueueView()
        }
    }

    @IBAction func playPauseButtonPressed(_ sender: AnyObject) {
        if self.playPauseButton.isSelected {
            PlaybackHandler.sharedInstance.resumePlayback();
        } else {
            PlaybackHandler.sharedInstance.pausePlayback();
        }
    }

    @IBAction func skipNextButtonPressed(_ sender: AnyObject) {
        PlaybackHandler.sharedInstance.skipPlaybackForward()
    }
    
    @IBAction func skipBackButtonPressed(_ sender: AnyObject) {
        PlaybackHandler.sharedInstance.skipPlaybackBackwards()
    }

    @IBAction func shuffleButtonPressed(_ sender: AnyObject) {
        PlaybackHandler.sharedInstance.isShuffleModeEnabled = !PlaybackHandler.sharedInstance.isShuffleModeEnabled
        self.updatePlaybackSettingsUI()
        self.queueTableVC.updateView()
        self.updateCarousel()
    }
    
    @IBAction func loopbuttonPressed(_ sender: AnyObject) {
        PlaybackHandler.sharedInstance.isRepeatModeEnabled = !PlaybackHandler.sharedInstance.isRepeatModeEnabled
        self.updatePlaybackSettingsUI()
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        
        //Add/Remove song to library
        guard let item = self.currentSong else {return}
        
        if (LibraryHandler.sharedInstance.doesItemExistInLibrary(item: item)) {
            showAlert(title: "Info", message: "This song is already in your library")
        } else {
            addSongToLibrary()
        }
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        
        if self.currentSong != nil {
            let options : [MusicOptionCellType] = MusicPopupContainerVC.optionsSongs
            showOptions(musicItem:currentSong!,options: options)
        }
    }
    
    //MARK: - Add/Remove from Library
    func addSongToLibrary() {
        
        self.addButton.isEnabled = false
        
        LibraryHandler.sharedInstance.addItemToLibrary(item:self.currentSong!, completion: {(success) in
            self.addButton.isEnabled = true
            if success {
                self.showAlert(title: "Success", message: "Song was added to your library")
                self.updateAddButton()
            } else {
                self.showAlert(title:"Error",message: "There was a problem adding this song to your library, please try again")
            }
        })
    }
    
    func removeSongFromLibrary() {
        self.addButton.isEnabled = false
        LibraryHandler.sharedInstance.removeItemFromLibrary(item:self.currentSong!, completion: {(success) in
            self.addButton.isEnabled = true
            if success {
                self.showAlert(title: "Success", message: "Song was removed to your library")
                self.updateAddButton()
            } else {
                self.showAlert(title:"Error",message: "There was a problem removing this song to your library, please try again")
            }
        })
    }
    
    func updateAddButton() {
        guard let item = self.currentSong else {return}
        if LibraryHandler.sharedInstance.doesItemExistInLibrary(item: item) {
            self.addButton.setImage(UIImage.init(named: "playback_add_button_sel"), for: UIControl.State.normal)
        } else {
            self.addButton.setImage(UIImage.init(named: "playback_add_button"), for: UIControl.State.normal)
        }
    }
    
    //MARK: - Options
    func showOptions(musicItem:MusicItem,options:[MusicOptionCellType]) {
        
        self.optionsVC = MusicPopupContainerVC.createFromStoryboard()
        self.optionsVC?.shouldHideStatusBar = true
        
        if self.optionsVC != nil {
            self.optionsVC?.setOptions(options)
            self.optionsVC?.musicItem = musicItem
            self.optionsVC?.showPopup(true)
            self.optionsVC?.originalVC = self
        }
    }
    
    //MARK: - Scrubs
    @objc func scrubbingDidStart(){
        //Stop scrubber updates
        self.isScrubbing = true
    }
    
    @objc func scrubbingDidStop(){
        
        //Restart scrubber updates
        let progress = self.scrubber.value
        PlaybackHandler.sharedInstance.seekCurrentSong(percentage: progress)
        
        //Delay update of isScrubbing flag to counter sub-second UI glitch
        DispatchQueue.main.asyncAfter(deadline: (.now() + 1.0)) {
            self.isScrubbing = false
        }
    }
    
    @objc func scrubberWasMoved(){
        if self.isScrubbing {
            
            let progress = self.scrubber.value
            if let totalDuration = PlaybackHandler.sharedInstance.currentSong?.getSongDurationSeconds() {
                let time = progress * totalDuration
                let remainingTime = (1.0-progress) * totalDuration
                self.updateTimeLabels(time: time, timeRemaining: remainingTime)
            }
        }
    }
    

    
    
    //MARK: - Carousel
    func updateCarousel(){
        if let currentIndex = PlaybackHandler.sharedInstance.getCurrentIndexInQueue() {
            self.carousel.reloadData()
            self.carousel.scrollToItem(at: currentIndex, animated: true)
        }
        else {
            self.carousel.currentItemIndex = 0
            self.carousel.reloadData()
        }
    }
    
    func numberOfItems(in carousel: iCarousel) -> Int {
        if let queue = PlaybackHandler.sharedInstance.getFullQueue() {
            return queue.count
        } else {
            return 0
        }
    }
    
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        if (option == .spacing) {return value * 1.1}
        if (option == .wrap) {return 0.0}
        if option == .visibleItems {return 3.0}
    
        return value
    }
    
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {

        var itemView: UIImageView
        
        //Reuse view if available, otherwise create a new view
        if let view = view as? UIImageView {
            itemView = view
        } else {
            itemView = UIImageView(frame: CGRect(x: 0, y: 0, width: 250, height: 250))
            itemView.contentMode = .scaleAspectFill
            itemView.clipsToBounds = true
        }
        
        //Get songs deets
        guard let queue = PlaybackHandler.sharedInstance.getFullQueue() else {return UIView()}
        guard index < queue.count else {return UIView()}
        
        let song = queue[index]
        if let imgURL = song.getImageURL() {
            itemView.backgroundColor = UIColor.clear
            itemView.sd_setImage(with: imgURL as URL?)
        } else {
            if song.isLocal {
                itemView.image = song.getLocalImage()
            } else {
                itemView.image = UIImage(named:"music_item_placeholder")
            }
        }

        itemView.layer.isDoubleSided = false
        return itemView
    }
    
    var isUserScrolling : Bool = false
    var initialScrollIndex : Int = 0
    
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        PlaybackHandler.sharedInstance.playSongFromQueue(index: index)
    }
    
    func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {

    }
    
    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        if isUserScrolling && (initialScrollIndex != carousel.currentItemIndex) {
            PlaybackHandler.sharedInstance.playSongFromQueue(index:self.carousel.currentItemIndex)
        }
        isUserScrolling = false
    }
    
    func carouselWillBeginDragging(_ carousel: iCarousel) {
        isUserScrolling = true
        initialScrollIndex = carousel.currentItemIndex
    }
    
    
}
