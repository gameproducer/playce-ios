//
//  MusicPopupContainerVC.swift
//  playce
//
//  Created by Tys Bradford on 5/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//


class MusicPopupContainerVC: PopupVC {

    
    @IBOutlet weak var cancelButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButtonBottomConstraint: NSLayoutConstraint!
    var customLoadingIndicator : CustomLoadIndicator!

    
    @IBOutlet weak var bgView: UIVisualEffectView!
    
    weak var tableVC : MusicPopupTableVC?
    var musicItem : MusicItem? {
        didSet {
            self.updateOptionsForSavedItems()
            self.tableVC?.updateView()
            self.retrievedSongs = []
        }
    }
    var parentItem : MusicItem?
    
    var originalVC : UIViewController?
    var retrievedSongs : [Song] = []
    
    var options : [MusicOptionCellType]?
    
    static let optionsArtistFollowed = [MusicOptionCellType.play,MusicOptionCellType.save,MusicOptionCellType.share]
    static let optionsArtist = [MusicOptionCellType.play,MusicOptionCellType.save,MusicOptionCellType.share]
    static let optionsSongs = [MusicOptionCellType.play,MusicOptionCellType.save,MusicOptionCellType.addPlaylist,MusicOptionCellType.addQueue,MusicOptionCellType.goArtist,MusicOptionCellType.share]
    static let optionsAlbums = [MusicOptionCellType.play,
                         MusicOptionCellType.save,
                         MusicOptionCellType.addPlaylist,
                         MusicOptionCellType.addQueue,
                         MusicOptionCellType.goArtist,
                         MusicOptionCellType.goAlbum,
                         MusicOptionCellType.share]
    static let optionsPlaylists = [MusicOptionCellType.play,
                            MusicOptionCellType.addQueue,
                            MusicOptionCellType.save,
                            MusicOptionCellType.share]
    static let optionSearch = [MusicOptionCellType.play,MusicOptionCellType.save,MusicOptionCellType.addPlaylist,MusicOptionCellType.addQueue,MusicOptionCellType.goArtist,MusicOptionCellType.goAlbum,MusicOptionCellType.share]
    
    
    static func createFromStoryboard()->MusicPopupContainerVC? {
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc : MusicPopupContainerVC? = storyboard.instantiateViewController(withIdentifier: "MusicPopupContainerVC") as? MusicPopupContainerVC
        return vc
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Loading
        self.customLoadingIndicator = CustomLoadIndicator(parentView: self.view)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "embedTable" {
            self.tableVC = segue.destination as? MusicPopupTableVC
            self.tableVC?.options = self.options
            self.tableVC?.containerVC = self
            self.resizeTableView()
        }
    }

    
    //MARK: - Setting Type
    func setOptions(_ options:[MusicOptionCellType]) {
        
        self.options = options

        if let tableVC = self.tableVC {
            tableVC.options = self.options
            tableVC.updateView()
        }
    }
    
    func updateOptionsForSavedItems() {
        
        guard let item = self.musicItem else {return}
        guard var options = self.options else {return}
        
        let isInLibrary = LibraryHandler.sharedInstance.doesItemExistInLibrary(item: item)
        if !isInLibrary {
            if let indexRemove = options.index(of: .remove) {
                options[indexRemove] = MusicOptionCellType.save
                self.setOptions(options)
            }
        } else if let indexSave = options.index(of: .save) {
            options[indexSave] = MusicOptionCellType.remove
            self.setOptions(options)
        }
    }
    
    
    func resizeTableView() {
        
        //Calculate the required height of the tableview and readjust the auto layout constraints so that the table sticks to the bottom of the screen
        guard let tableHeight = self.tableVC?.calculateTableHeight() else {return}
        let cancelButtonHeight : CGFloat = self.cancelButtonHeightConstraint.constant
        let screenHeight : CGFloat = (UIApplication.shared.keyWindow?.bounds.height)!
        
        var newContentInset : CGFloat = 0.0
        self.tableHeightConstraint.constant = screenHeight - cancelButtonHeight

        if tableHeight + cancelButtonHeight > screenHeight {
            newContentInset = 0.0
        } else {
            newContentInset = screenHeight - tableHeight - cancelButtonHeight
        }
        
        self.tableVC?.tableView.contentInset = UIEdgeInsets(top: newContentInset, left: 0.0, bottom: 0.0, right: 0.0)

    }
    
    
    //MARK: - Button Handler
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        hidePopup(true)
    }
    
    
    //MARK: - Show/Hide
    func showPopup(_ animated:Bool) {
        super.show(aboveAll: BTPopupAnimation.none)
        self.animateViewIn()
        
    }
    
    func hidePopup(_ animated:Bool) {
        if animated {self.animateViewOut()}
        else {self.hide(BTPopupAnimation.none)}
    }
    
    let kPopupAnimationDuration = 0.7
    func animateViewIn() {
        
        guard let tableHeight = self.tableVC?.calculateTableHeight() else {return}
        let cancelButtonHeight : CGFloat = self.cancelButtonHeightConstraint.constant
        self.cancelButtonBottomConstraint.constant = -(tableHeight+cancelButtonHeight)
        self.view.layoutIfNeeded()
        
        self.cancelButtonBottomConstraint.constant = 0.0
        
        UIView.animate(withDuration: kPopupAnimationDuration, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            
        }, completion: nil)
        
        UIView.animate(withDuration: kPopupAnimationDuration) {
            let blur = UIBlurEffect(style: UIBlurEffect.Style.light)
            self.bgView.effect = blur;
        }
    }
    
    func animateViewOut() {
        
        guard let tableHeight = self.tableVC?.calculateTableHeight() else {return}
        let cancelButtonHeight : CGFloat = self.cancelButtonHeightConstraint.constant
        self.cancelButtonBottomConstraint.constant = -(tableHeight+cancelButtonHeight)
        
        UIView.animate(withDuration: kPopupAnimationDuration, animations: {
            self.bgView.effect = nil;
            self.view.layoutIfNeeded()
        }, completion: {
            finished in
            if finished {super.hide(BTPopupAnimation.none)}
        })
    }
    
    //MARK: - Selection Handler
    func selectionMade(cellType: MusicOptionCellType?) {
        
        guard let cellType = cellType else {return}
        
        switch cellType {
        case .play:
            self.playSelected()
            break
        case .save:
            self.saveSelected()
            break
        case .remove:
            self.removeSelected()
            break
        case .share:
            self.shareSelected()
            break
        case .addPlaylist:
            self.addPlaylistSelected()
            break
        case .addQueue:
            self.addQueueSelected()
            break
        case .goAlbum:
            self.goAlbumSelected()
            break
        case .goArtist:
            self.goArtistSelected()
            break
        case .edit:
            if let playlist = musicItem as? Playlist {
                goPlaylist(playlist: playlist)
            }
            break
        }
    }
    
    func playSelected(){
        
        if let song = self.musicItem as? Song {
            self.playSong(song: song)
            self.hidePopup(true)
        } else if self.retrievedSongs.count > 0 {
            self.playSongs(songs: self.retrievedSongs)
            self.hidePopup(true)
        } else {
            self.retrieveSongs(item: self.musicItem, completion: {(success, songs) in
                if songs != nil {self.playSongs(songs: songs!)}
                self.hidePopup(true)
            })
        }
    }
    
    func saveSelected(){
        
        guard let item = self.musicItem else {return}
        
        self.customLoadingIndicator.startAnimating()
        LibraryHandler.sharedInstance.addItemToLibrary(item:item, completion: {(success) in
            
            self.customLoadingIndicator.stopAnimating()
            if success {
                //self.updateOptionsForSavedItems()
                self.hidePopup(true)
            } else {

            }
        })
    }
    
    func removeSelected() {
        
        guard let item = self.musicItem else {return}
        
        //Check if we are removing track from playlist
        if let playlist = self.parentItem as? Playlist {
            guard let item = self.musicItem as? Song else {return}
            self.customLoadingIndicator.startAnimating()
            APIManager.sharedInstance.removeTrackFromPlaylist(playlist: playlist, song: item, completion: { (success, playlist) in
                self.customLoadingIndicator.stopAnimating()
                if success {
                    if let detailsVC = self.originalVC as? MusicDetailTableVC {
                        detailsVC.musicItem = playlist
                        detailsVC.updateData()
                    }
                    self.hidePopup(true)
                } else {

                }
            })
            
        } else {
            self.customLoadingIndicator.startAnimating()
            LibraryHandler.sharedInstance.removeItemFromLibrary(item:item, completion: {(success) in
                
                self.customLoadingIndicator.stopAnimating()
                if success {
                    
                    //Update underlying VC
                    if let songVC = self.originalVC as? SongsViewController {songVC.updateSongs()}
                    else if let artistVC = self.originalVC as? ArtistTableVC {artistVC.updateArtists()}
                    else if let albumVC = self.originalVC as? AlbumTableVC {albumVC.updateAlbums()}
                    else if let playlistVC = self.originalVC as? PlaylistTableVC {playlistVC.updatePlaylists()}
                    else if let musicDetailTableVC = self.originalVC as? MusicDetailTableVC {musicDetailTableVC.updateData()}
                    self.hidePopup(true)
                } else {

                }
            })
        }
    }
    
    func shareSelected(){
        
        //Get share content (text, image, url etc.)
        guard let item = self.musicItem else {return}
        let text = SocialShareManager.getShareTextForItem(item:item)
        let url = SocialShareManager.getShareURLForItem(item:item)
        let image = SocialShareManager.getShareImageForItem(item:item)
        
        var activityItems : [Any] = [text,url]
        if image != nil {activityItems.append(image!)}
        
        //Present in UIActivityController
        let ac = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        ac.excludedActivityTypes = [
            UIActivity.ActivityType.airDrop,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.saveToCameraRoll,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToWeibo]
        self.present(ac, animated: true, completion: nil)
        
    }
    
    func addPlaylistSelected(){
        
        //Check item is not itunes
        if self.musicItem!.getProviderType() == .iTunes {
            self.originalVC?.showAlert(title:"Warning",message: "It is currently not possible to add iTunes tracks to playlists")
            return
        }
        
        guard let song = self.musicItem as? Song else {return}
        
        let playlistVC = self.storyboard?.instantiateViewController(withIdentifier: "PlaylistTableVC") as! PlaylistTableVC
        let navController = PLNavController()
        playlistVC.addingTrack = song
        
        navController.viewControllers = [playlistVC]
        navController.setBackButtonVisible(false)
        navController.setMenuButtonVisible(false)
        navController.showSearchButton(false)
        originalVC?.present(navController, animated: true, completion: nil)
        hidePopup(false)
    }
    
    func addQueueSelected(){
        
        //If song already in queue remove
        //Else add to queue
        if let song = self.musicItem as? Song {
            PlaybackHandler.sharedInstance.addSongToQueue(song: song)
            self.hidePopup(true)
        } else {
            if self.retrievedSongs.count > 0 {
                PlaybackHandler.sharedInstance.addSongsToQueue(songs:self.retrievedSongs)
                self.hidePopup(true)
            } else {
                
                self.retrieveSongs(item: self.musicItem, completion: {(success, songs) in
                    if songs != nil {PlaybackHandler.sharedInstance.addSongsToQueue(songs:songs!)}
                    self.hidePopup(true)
                })
            }
        }
    }
    
    func goPlaylist(playlist:Playlist) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
        vc.musicItem = playlist
        originalVC?.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goArtistSelected(){
        
        var finalArtist : Artist?
        if let song = self.musicItem as? Song {
            if let artist = song.artistList?.first {
                finalArtist = artist
            }
        } else if let album = self.musicItem as? Album {
            if let artist = album.artistList?.first {
                finalArtist = artist
            }
        } else if let artist = self.musicItem as? Artist {
            finalArtist = artist
        }
        
        finalArtist?.provider = self.musicItem?.provider
        
        //Go to Unified Artist
        if let artist = finalArtist {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "UnifiedArtistVC") as! UnifiedArtistVC
            vc.artist = artist
            
            //Check if coming from FullPlayer
            guard let originalVC = originalVC else {
                self.hidePopup(true)
                return
            }
            
            if let fullPlayerVC = originalVC as? PlaybackFullVC {
                //Close full player and navigate to artist
                if let mainVC = getSliderVC().mainViewController {
                    if let navController = mainVC as? UINavigationController {
                        navController.pushViewController(vc, animated: true)
                        fullPlayerVC.closePlayer()
                    }
                }
            } else {
                originalVC.navigationController?.pushViewController(vc, animated: true)
            }
        }
        
        self.hidePopup(true)
    }
    
    func goAlbumSelected(){
        
        //TODO: Need a way to go from a track to Album. This requires more info coming in from BE
        
        if let album = self.musicItem as? Album {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
            vc.musicItem = album
            vc.isSearchDetail = true
            originalVC?.navigationController?.pushViewController(vc, animated: true)
        }
        
        self.hidePopup(true)
    }
    
    func retrieveSongs(item:MusicItem?,completion: ((Bool,[Song]?)->Void)?) {
        
        guard let item = item else {
            completion?(false,[])
            return
        }
        
        if let artist = item as? Artist {
            APIManager.sharedInstance.getSongsForArtist(artist, completion: { (success, songs) in
                if completion != nil {completion!(success,songs)}
            })
        } else if (item is Album || item is Playlist) {
            guard let listID = item.id else {
                completion?(false,[])
                return
            }
            APIManager.sharedInstance.getSongsFromBackend(listID, completion: { (success, songs) in
                if completion != nil {completion!(success,songs)}
            })
        } else {
            completion?(false,[])
        }
    }
    
}
