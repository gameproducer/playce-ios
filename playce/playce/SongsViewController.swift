//
//  SongsViewController.swift
//  playce
//
//  Created by Benjamin Hendricks on 6/4/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import MediaPlayer
import SlideMenuControllerSwift

class SongsViewController: MusicTableVC {

    var mediaQuery: MPMediaQuery? = MPMediaQuery.songs()
    var vcTitle : String?
    
    var mySongs : [Song]  = []
    var mySongsTotalDuration = 0
    var listID : String?
    var artist : Artist?
    
    var addingToPlaylist : Playlist?
    var playlistSongs : [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Navbar
        if vcTitle != nil {
            self.title = vcTitle
        } else {
            self.title = "Your Songs"
        }
        
        if (self.addingToPlaylist != nil) {
            let button = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(doneButtonPressed))
            self.navigationItem.rightBarButtonItem = button
        }
        
        // Table
        self.tableView.showsVerticalScrollIndicator = true

        // Old Itunes integration snippet
        guard UserDefaults.standard.bool(forKey: "ITUNES_CONNECTED") else {
            mediaQuery = nil
            tableView.reloadData()
            return
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSongs()
        
        if (self.addingToPlaylist != nil) {
            if let navController = self.navigationController as? PLNavController {
                navController.showSearchButton(false)
            }
        }
    }
    
    // MARK: - Data
    func updateSongs() {
        
        if mySongs.count == 0 {
            self.customLoadingIndicator.startAnimating()
        }
        
        if listID != nil {
            APIManager.sharedInstance.getSongsFromBackend(listID!, completion: { (success, songs) in
                
                self.customLoadingIndicator.stopAnimating()
                if success {
                    
                    if let newSongs = songs {self.mySongs = newSongs}
                    self.updateTotalDuration()
                    self.tableView.reloadData()
                    
                } else {
                    
                    //Show dialog or empty cell
                    
                }
            })
        }
        else if artist != nil {
            
            APIManager.sharedInstance.getSongsForArtist(artist!, completion: { (success, songs) in
                
                self.customLoadingIndicator.stopAnimating()
                if success {
                    
                    if let newSongs = songs {self.mySongs = newSongs}
                    self.updateTotalDuration()
                    self.tableView.reloadData()
                    
                } else {
                    
                    //Show dialog or empty cell
                    
                }
            })
        }
        else {
            
            APIManager.sharedInstance.getMySongsFromBackend({ (success, songs) in
                
                self.customLoadingIndicator.stopAnimating()
                
                self.mySongs = songs
                if ItunesHandler.sharedInstance.isItunesConnected() && self.addingToPlaylist == nil {
                    self.mySongs = self.mySongs + ItunesHandler.sharedInstance.getAllMySongs()
                }
                
                self.updateTotalDuration()
                self.tableView.reloadData()
            })
        }
    }
    
    func updateTotalDuration() {
        
        var totalMillis = 0
        for song in self.mySongs {
            if let duration = song.durationMilli {totalMillis = totalMillis + duration}
        }
        
        self.mySongsTotalDuration = totalMillis
    }
    
    
    // MARK: - Table
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mySongs.count + 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if (indexPath as NSIndexPath).row == mySongs.count {
            return 105.0
        } else {
            return 72.0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath as NSIndexPath).row == mySongs.count {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicFooterCell", for: indexPath) as! MusicFooterCell
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            
            let titleString = (mySongs.count == 1 ? "1 SONG" : String(mySongs.count) +  " SONGS")
            cell.titleLabel.text = titleString
            
            let totalDurationMinutes = ((Double(mySongsTotalDuration)/1000.0)/60.0)
            cell.subtitleLabel.text = String(format: "%d MINUTES", Int(totalDurationMinutes))
            
            if totalDurationMinutes == 0.0 {
                cell.subtitleLabel.isHidden = true
            } else{
                cell.subtitleLabel.isHidden = false
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
            let song : Song = mySongs[(indexPath as NSIndexPath).row]
            cell.musicItem = song
            cell.moreButton.tag = (indexPath as NSIndexPath).row
            
            if (self.addingToPlaylist != nil) {
                cell.moreButton.isHidden = true
                if (self.isSongInPlaylist(song: song)) {
                    cell.providerThumbnail.image = UIImage(named: "ic_tick_green")
                } else {
                    cell.providerThumbnail.image = UIImage(named: "ic_plus_grey")
                }
            }
            
            return cell
        }
    }
    
    func isSongInPlaylist(song:Song) -> Bool {
        guard let songID = song.id else {return false}
        
        for track in self.playlistSongs {
            
            if let trackID = track.id {
                if (trackID == songID) {return true}
            }
        }
        
        return false
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedSong = getSongForIndexPath(indexPath)
        
        //Play the selected song
        if let song = selectedSong {
            
            //Check if we are adding to playlist
            if (self.addingToPlaylist != nil) {
                self.songSelectedInPlaylistMode(song: song)
            } else {
                //self.playSong(song:song)
                self.playSongsWithinList(song: song, list: self.mySongs)
            }
        }
    }
    
    func getSongForIndexPath(_ indexPath:IndexPath)->Song? {
        
        if mySongs.count > (indexPath as NSIndexPath).row {
            return mySongs[(indexPath as NSIndexPath).row]
        } else {return nil}
    }
    
    
    // MARK - Button Handler
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        
        let song = getSongForIndexPath(IndexPath(row: sender.tag, section: 0))
        super.showOptions(musicItem: song,options: MusicPopupContainerVC.optionsSongs)
    }

    @objc func doneButtonPressed() {
        self.dismiss(animated: true, completion: {
        })
    }
    
    
    
    // MARK: - Playlist
    func songSelectedInPlaylistMode(song:Song) {
        
        if song.getProviderType() == .iTunes {
            self.showAlert(title:"Warning",message: "It is currently not possible to add iTunes tracks to playlists")
            return
        }
        
        self.customLoadingIndicator.startAnimating()
        if (self.isSongInPlaylist(song: song)) {
            
            //Remove
            APIManager.sharedInstance.removeTrackFromPlaylist(playlist: self.addingToPlaylist!, song: song, completion: { (success, playlist) in
                
                self.customLoadingIndicator.stopAnimating()
                if (success) {
                    //Update songs in playlist and update view
                    self.updateSongsInPlaylist()
                } else {
                    self.showAlert(title: "Uh oh", message: "There was a problem removing this song from the playlist. Please try again")
                }
            })
            
        } else {
            
            //Add
            APIManager.sharedInstance.addTrackToPlaylist(playlist: self.addingToPlaylist!, song: song, completion: { (success, playlist) in
                
                self.customLoadingIndicator.stopAnimating()
                if (success) {
                    //Update songs in playlist and update view
                    self.updateSongsInPlaylist()
                } else {
                    self.showAlert(title: "Uh oh", message: "There was a problem adding this song to the playlist. Please try again")
                }
            })
        }
    }
    
    func updateSongsInPlaylist() {
        
        guard let playlist = self.addingToPlaylist else {return}
        guard let playlistID = playlist.id else {return}
        
        self.customLoadingIndicator.startAnimating()
        APIManager.sharedInstance.getSongsFromBackend(playlistID, completion: {(success, songs) in
            
            self.customLoadingIndicator.stopAnimating()
            if (success && songs != nil) {self.playlistSongs = songs!}
            self.tableView.reloadData()
        })
    }
    
}
