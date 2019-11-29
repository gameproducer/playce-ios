//
//  ExtendedSearchTableVC.swift
//  playce
//
//  Created by Tys Bradford on 21/02/2017.
//  Copyright © 2017 gigster. All rights reserved.
//

import Foundation


class ExtendedSearchTableVC : UITableViewController {

    var searchString : String = ""
    var provider : ProviderType = .none
    var results : [MusicItem]?
    var optionsVC : MusicPopupContainerVC?
    var searchItem: MusicItem?
    var customLoadingIndicator : CustomLoadIndicator?
    var customTitle : String?
    var isSearchDetail : Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TableView
        self.tableView.tableFooterView = UIView()
        
        //PlaybackBar UI handling
        self.adjustForPlaybackBar()
        
        //Loading indicator
        self.customLoadingIndicator = CustomLoadIndicator(parentView: self.view)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Update navbar
        if self.customTitle != nil {
            self.title = customTitle
        } else {
            let providerName = ProviderObject.getProviderNameFromType(provider: self.provider)
            self.title = "More From \(providerName)"
        }
        
        //Navbar
        if let navcontroller = self.navigationController as? PLNavController {
            navcontroller.showSearchButton(false)
        }
        
        //Check if we are search detail mode
        if (self.searchItem != nil) && (results == nil) {
            
            self.title = searchItem!.name
            self.performDetailedSearch(item:self.searchItem!)
        }
    }
    
    func performDetailedSearch(item:MusicItem) {
        
        guard let itemID = item.externalId else {return}
        var spotifyPlaylistOwner : String?
        if item.getProviderType() == .spotify {
            if let playlist = item as? Playlist {
                spotifyPlaylistOwner = playlist.owner
            }
        }
        self.customLoadingIndicator?.startAnimating()
        
        APIManager.sharedInstance.searchDetails(provider: item.getProviderType(), resultType: item.getItemType(), externalID: itemID, results: 50, pageToken: nil, spotifyPlaylistOwner: spotifyPlaylistOwner, completion:
            {(success,results,nextPageToken) in
            
            self.customLoadingIndicator?.stopAnimating()
            if success {
                self.results = results
            } else {
                self.results = []
            }
            self.tableView.reloadData()
        })
    }


    //MARK: - TableView delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.results == nil {return 1}
        else {return (self.results?.count)!}
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
        let musicItem = self.results?[indexPath.row]
        cell.musicItem = musicItem
        cell.moreButton.tag = (indexPath as NSIndexPath).row
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.results == nil || self.results?.count == 0 {return}
        if let item = self.results?[indexPath.row] {
            self.didSelectItem(item: item)
        }
    }



    //MARK: - Navigation
    func didSelectItem(item:MusicItem) {
        
        //If song, play. Else go to more detail
        
        if let song = item as? Song {
            //Play song
            self.playSong(song:song)
            
        } else if let album = item as? Album {
            //Go to detail
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
            vc.isSearchDetail = self.isSearchDetail
            vc.musicItem = album
            self.navigationController?.pushViewController(vc, animated: true)
            
        } else if let playlist = item as? Playlist {
            //Go to detail
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
            vc.musicItem = playlist
            vc.isSearchDetail = self.isSearchDetail
            self.navigationController?.pushViewController(vc, animated: true)
            
        } else if let artist = item as? Artist {
            //Go to detail
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
            vc.musicItem = artist
            vc.isSearchDetail = self.isSearchDetail
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        
        let index = sender.tag
        let item = self.results![index]
        
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
        
        showOptions(musicItem: item,options: options)
    }


    //MARK: - Options
    func showOptions(musicItem:MusicItem?,options:[MusicOptionCellType]){
        
        //TODO: Find proper fix for this weird overlay problem
        /*
         if self.optionsVC == nil {
         self.optionsVC = MusicPopupContainerVC.createFromStoryboard()
         self.optionsVC?.shouldHideStatusBar = true
         }
         */
        
        self.optionsVC = MusicPopupContainerVC.createFromStoryboard()
        self.optionsVC?.shouldHideStatusBar = true
        
        if self.optionsVC != nil {
            self.optionsVC?.options = options
            self.optionsVC?.musicItem = musicItem
            self.optionsVC?.showPopup(true)
            self.optionsVC?.originalVC = self
        }
    }

}
