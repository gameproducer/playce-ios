//
//  MusicDetailTableVC.swift
//  playce
//
//  Created by Tys Bradford on 10/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import SDWebImage

class MusicDetailTableVC: MusicTableVC, UITextFieldDelegate {

    fileprivate let kHeroViewHeight : CGFloat = 375.0
    var headerView: UIView!
    
    @IBOutlet weak var heroImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var titleField: UITextField!
    
    
    var musicItem : MusicItem?
    var songs : [Song]? = []
    var isSearchDetail : Bool = false
    
    var isNewPlaylist = false;
    
    @IBOutlet weak var heroTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var heroBottomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Header View
        initHeaderView()

        //Details
        initDetails()
        
        //PlaybackBar UI handling
        self.adjustForPlaybackBar()
        
        //Footer view
        let footerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 0.0))
        footerView.backgroundColor = UIColor.white
        self.tableView.tableFooterView = footerView
        
        //Edit title
        if self.canEditPlaylist() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(didTapTitle))
            self.titleLabel.isUserInteractionEnabled = true
            self.titleLabel.addGestureRecognizer(tap);
            self.titleField.delegate = self
        }
        
        if (isNewPlaylist) {
            self.titleLabel.text = "New Playlist"
            subtitleLabel.text = ""
        }
        
    }
    
    deinit {
        self.removeListenersForPlaybackHideShow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isSearchDetail {
            if (self.songs == nil || self.songs?.count == 0) && self.musicItem != nil {
                self.performDetailedSearch(item: self.musicItem!)
            }
        } else if (!self.isNewPlaylist) {
            updateData()
        }
        
        //Set appearance of remove button
        let font = UIFont(name: ".SFUIText-Semibold", size: 10.0)
        let color = PLStyle.greenColor()
        let attributes = [NSAttributedString.Key.font:font,NSAttributedString.Key.foregroundColor:color]
        let attributedTitle = NSAttributedString(string: "REMOVE", attributes: attributes)
        UIButton.appearance(whenContainedInInstancesOf: [UIView.self,MusicItemCell.self]).setAttributedTitle(attributedTitle, for: .normal)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (isNewPlaylist) {
            self.didTapTitle()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Remove custom button appearance
        UIButton.appearance(whenContainedInInstancesOf: [UIView.self,MusicItemCell.self]).setAttributedTitle(nil, for: .normal)
    }
    
    func initHeaderView() {
        
        headerView = tableView.tableHeaderView
        tableView.tableHeaderView = nil
        tableView.addSubview(headerView)
        tableView.contentInset = UIEdgeInsets(top: kHeroViewHeight, left: 0, bottom: 0, right: 0)
        tableView.contentOffset = CGPoint(x: 0, y: -kHeroViewHeight)
        updateHeaderView()
    }
    
    func updateHeaderView() {
        
        let yOffset = tableView.contentOffset.y
        var headerRect = CGRect(x: 0, y: -kHeroViewHeight, width: tableView.bounds.width, height: kHeroViewHeight)
                
        if yOffset < -kHeroViewHeight {
            //Pulling down
            headerRect.origin.y = yOffset
            headerRect.size.height = -yOffset
        }
        
        headerView.frame = headerRect
    }
    
    func initDetails() {
        
        guard let item = self.musicItem else {return}
        
        //Labels
        if let album = item as? Album {
            titleLabel.text = album.name
            subtitleLabel.text = album.getArtistNameString()
            setTruncatedTitle(album.name)
        } else if let artist = item as? Artist {
            titleLabel.text = artist.name
            subtitleLabel.text = ""
            setTruncatedTitle(artist.name)
        } else if let playlist = item as? Playlist {
            titleLabel.text = playlist.name
            subtitleLabel.text = ""
            setTruncatedTitle(playlist.name)
        }
        
        //Set image
        if item.isLocal {
            self.heroImage.image = item.getLocalImage()
        } else {
            if let imgURL = item.getImageURL() {
                
                if !SDWebImageManager.shared().cachedImageExists(for: imgURL){
                    
                    SDWebImageManager.shared().downloadImage(with: imgURL, options: [], progress: nil, completed: { (downloadedImage, error, cacheType, success, url) in
                        
                        //Fade in image
                        self.heroImage.alpha = 0.0
                        self.heroImage.image = downloadedImage
                        UIView.animate(withDuration: 0.5, animations: {
                            self.heroImage.alpha = 1.0
                        })
                    })
                    
                } else {
                    heroImage.sd_setImage(with: imgURL)
                }
            } else {
                heroImage.image = UIImage(named:"music_item_placeholder")
            }
        }
    }
    
    func updateData() {
        
        guard let item = self.musicItem else {return}
        if item.isLocal {
            self.getLocalChildItems(item: item)
            return
        }
        
        let itemID = item.id
        if itemID == nil {return}
        
        if item.isKind(of: Album.self) ||  item.isKind(of: Playlist.self){
            APIManager.sharedInstance.getSongsFromBackend(itemID!, completion: { (success, songs) in
                if success {
                    self.songs = songs
                    self.tableView.reloadData()
                }
            })
        } else if item.isKind(of: Artist.self) {

            APIManager.sharedInstance.getSongsForArtist((item as! Artist), completion: { (success, songs) in
                
                if success {
                    self.songs = songs
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func performDetailedSearch(item:MusicItem) {

        if item.externalId == nil {return}
        
        var spotifyPlaylistOwner : String?
        if item.getProviderType() == .spotify {
            if let playlist = item as? Playlist {
                spotifyPlaylistOwner = playlist.owner
            }
        }
        self.customLoadingIndicator?.startAnimating()
        
        APIManager.sharedInstance.searchDetails(provider: item.getProviderType(), resultType: item.getItemType(), externalID: item.externalId!, results: 50, pageToken: nil, spotifyPlaylistOwner: spotifyPlaylistOwner, completion:
            {(success,results,nextPageToken) in
                
                self.customLoadingIndicator?.stopAnimating()
                if success {
                    self.songs = results
                } else {
                    self.songs = []
                }
                self.tableView.reloadData()
        })
    }
    
    func getLocalChildItems(item:MusicItem) {
        
        if item.isKind(of: Album.self) {
            self.songs = ItunesHandler.sharedInstance.getSongsForAlbum(item: item)
        } else if item.isKind(of: Artist.self) {
            self.songs = ItunesHandler.sharedInstance.getSongsForArtist(item: item)
        } else if item.isKind(of: Playlist.self) {
            self.songs = ItunesHandler.sharedInstance.getSongsForPlaylist(item: item)
        }
        
        self.tableView.reloadData()
    }
    
    
    //MARK: - Table Data
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (section == 0) {
            if (self.canEditPlaylist()) {return 1}
            else {return 0}
        }
        else if songs != nil {return songs!.count}
        else {return 0}
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.section == 0) {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "addSongCell", for: indexPath)
            return cell
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
        
        //Set cell
        cell.musicItem = songs?[(indexPath as NSIndexPath).row]
        
        //If album show the track number not the track image
        let numberLabel = cell.viewWithTag(100) as? UILabel
        if (self.musicItem as? Album) != nil {
            
            cell.thumbnail.isHidden = true
            if numberLabel != nil {
                numberLabel!.text = String((indexPath as NSIndexPath).row + 1)
                numberLabel?.isHidden = false
            }
        } else {
            
            cell.thumbnail?.isHidden = false
            if numberLabel != nil {
                numberLabel?.isHidden = true
            }
        }
        
        //More button
        cell.moreButton.tag = indexPath.row
        cell.moreButton.setAttributedTitle(nil, for: UIControl.State.normal)
    
        return cell
    }
    
    
    //MARK: - Table Actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 0) {self.addSong()}
        else {self.songWasSelected(index: indexPath.row)}
    }
    
    func getSongForIndexPath(_ indexPath:IndexPath)->Song? {
        
        guard songs != nil else {return nil}
        guard songs!.count > indexPath.row else {return nil}
        
        if let selectedSong = songs?[(indexPath as NSIndexPath).row] {return selectedSong}
        else {return nil}
    }
    
    func songWasSelected(index:Int) {
        
        guard let songs = self.songs else {return}
        guard let song = self.songs?[index] else {return}
        self.playSongsWithinList(song: song, list: songs)
    }
    
    func getSongsStartingFromIndex(index:Int) -> [Song] {
        
        guard songs != nil else {return []}
        guard songs!.count > index else {return []}
        guard songs!.count > 0 else {return []}
        
        let finalIndex = songs!.count - 1
        let playSongs = self.songs![index...finalIndex]
        return Array(playSongs)
    }
    
    
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        let song = getSongForIndexPath(IndexPath(row: sender.tag, section: 0))
        let playlist = self.musicItem as? Playlist
        super.showOptionsWithPlaylist(musicItem: song, options: MusicPopupContainerVC.optionsSongs, playlist: playlist)
        //super.showOptions(musicItem: song,options: MusicPopupContainerVC.optionsSongs)
    }
    
    
    //MARK: - Scroll Delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
    }
    
    
    //MARK: - Button Handler
    
    @IBAction func optionButtonPressed(_ sender: AnyObject) {
        
        guard let item = self.musicItem else {return}
        let type = item.getItemType()
        var options : [MusicOptionCellType] = []
        
        switch type {
        case .track:
            options = MusicPopupContainerVC.optionsSongs
            break
        case .artist:
            options = MusicPopupContainerVC.optionsArtist
            break
        case .album:
            options = MusicPopupContainerVC.optionsAlbums
            break
        case .playlist:
            options = MusicPopupContainerVC.optionsPlaylists
            break
        default:
            break
        }
        
        showOptions(musicItem: self.musicItem,options: options)
        if self.songs != nil {self.optionsVC?.retrievedSongs = self.songs!}
    }
    
    
    //MARK: - Playlist Editting
    func canEditPlaylist() -> Bool {
        
        if self.isNewPlaylist {return true}
        guard let playlist = self.musicItem as? Playlist else {return false}
        
        //Check if this playlist is in my library. If not, do not allow editing
        return LibraryHandler.sharedInstance.doesItemExistInLibrary(item: playlist)
    }
    
    @objc func didTapTitle() {
        self.titleField.text = self.titleLabel.text
        self.titleField.becomeFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if (self.canEditPlaylist() && indexPath.section != 0) {return UITableViewCell.EditingStyle.delete}
        else {return UITableViewCell.EditingStyle.none}
    }
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCell.EditingStyle.delete {
            self.removeSongFromPlaylist(index: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let remove = UITableViewRowAction(style: .normal, title: "REMOVE") { action, index in
            self.removeSongFromPlaylist(index: index.row)   
        }
        
        remove.backgroundColor = UIColor.white
        return [remove]
    }
    
    func removeSongFromPlaylist(index:Int) {
        
        self.customLoadingIndicator.startAnimating()
        guard let playlist = self.musicItem as? Playlist else {return}
        guard let track = self.songs?[index] else {return}
        
        APIManager.sharedInstance.removeTrackFromPlaylist(playlist: playlist, song: track, completion: {(success, playlist) in
            
            self.customLoadingIndicator.stopAnimating()
            
            if (success) {
                self.musicItem = playlist
                self.updateData()
            } else {
                let ac = UIAlertController(title: "Uh oh", message: "There was an error removing this song from the playlist. Please try again later", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                ac.addAction(okAction)
                self.present(ac, animated: true, completion: nil)
            }
        })
    }
    
    //MARK: - Textfield Delegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        self.titleField.isHidden = false
        self.titleLabel.isHidden = true;
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
     
        guard let playlistName = self.titleField.text else {
            self.showAlert(title: "Uh oh", message: "Please enter a valid playlist name")
            return false
        }
        
        //Check name has actually changed
        if playlistName == self.musicItem?.name {
            textField.resignFirstResponder()
            return true
        }
        
        self.customLoadingIndicator.startAnimating()
        if (self.isNewPlaylist) {
            APIManager.sharedInstance.createPlaylist(name: playlistName, completion: { (success, playlist) in
                self.customLoadingIndicator.stopAnimating()
                if (success) {
                    self.musicItem = playlist
                    self.isNewPlaylist = false
                    self.initDetails()
                } else {
                    self.showAlert(title: "Uh oh", message: "There was a problem creating this playlist. Please try again")
                }
            })
        } else {
            guard let playlist = self.musicItem as? Playlist else {return true}
            APIManager.sharedInstance.renamePlaylist(playlist: playlist,name:playlistName, completion: { (success, updatedPlaylist) in
                
                self.customLoadingIndicator.stopAnimating()
                if (success) {
                    self.musicItem = updatedPlaylist
                    self.initDetails()
                } else {
                    self.showAlert(title: "Uh oh", message: "There was a problem renaming this playlist. Please try again")
                }
            })
        }
        
        self.titleField.isHidden = true
        self.titleLabel.isHidden = false;
        textField.resignFirstResponder()
        
        return true
    }
    
    func addSong() {

        //Check that playlist actually exists first
        guard let playlist = self.musicItem as? Playlist else {return}
        
        let songsVC = self.storyboard?.instantiateViewController(withIdentifier: "SongsViewController") as! SongsViewController
        let navController = PLNavController()
        songsVC.addingToPlaylist = playlist
        if (self.songs != nil) {songsVC.playlistSongs = self.songs!}
        
        navController.viewControllers = [songsVC]
        navController.setBackButtonVisible(false)
        navController.setMenuButtonVisible(false)
        navController.showSearchButton(false)
        self.present(navController, animated: true, completion: nil)
    }
    
    
    
}
