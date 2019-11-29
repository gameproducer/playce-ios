//
//  PlaylistTableVC.swift
//  playce
//
//  Created by Tys Bradford on 14/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class PlaylistTableVC: MusicTableVC {

    var myPlaylists : [Playlist] = []
    var addingTrack : Song?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Navbar
        self.title = "Your Playlists"
        
        // Table
        self.tableView.showsVerticalScrollIndicator = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePlaylists()
        
        //Navbar
        if (self.addingTrack != nil) {
            
            if let navController = self.navigationController as? PLNavController {
                navController.showSearchButton(false)
            }
            
            let button = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: #selector(didCancelAddingTrack))
            self.navigationItem.leftBarButtonItem = button
        }
    }
    
    // MARK: - Data
    func updatePlaylists() {
        
        if myPlaylists.count == 0 {
            self.customLoadingIndicator.startAnimating()
        }
        
        APIManager.sharedInstance.getPlaylistsFromBackend { (success, playlists) in
            
            self.customLoadingIndicator.stopAnimating()
            
            self.myPlaylists = playlists!
            if ItunesHandler.sharedInstance.isItunesConnected() {
                self.myPlaylists = self.myPlaylists + ItunesHandler.sharedInstance.getAllMyPlaylists()
            }
            
            self.tableView.reloadData()
        }
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0) {return 1}
        else {return myPlaylists.count+1}
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).row == myPlaylists.count {
            return 105.0
        } else {
            return 72.0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if (indexPath.section == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addPlaylistCell", for: indexPath)
            return cell
        }
        else if (indexPath as NSIndexPath).row == myPlaylists.count {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicFooterCell", for: indexPath) as! MusicFooterCell
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            
            let titleString = (myPlaylists.count == 1 ? "1 PLAYLIST" : String(myPlaylists.count) +  " PLAYLISTS")
            cell.titleLabel.text = titleString
            
            let totalSongs = 0
            cell.subtitleLabel.text = String(format: "%d SONGS", totalSongs)
            
            if totalSongs == 0 {
                cell.subtitleLabel.isHidden = true
            } else{
                cell.subtitleLabel.isHidden = false
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
            let playlist = myPlaylists[(indexPath as NSIndexPath).row]
            cell.musicItem = playlist
            cell.moreButton.tag = (indexPath as NSIndexPath).row
            
            if (self.addingTrack != nil) {cell.moreButton.isHidden = true}
            else {cell.moreButton.isHidden = false}
            
            return cell
        }

    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 0) {
            createPlaylist()
        }
        else if (self.addingTrack != nil) {
            self.playlistSelectedToAddTrack(playlist: getPlaylistForIndexPath(indexPath))
        }
        else {
            goToSongs(getPlaylistForIndexPath(indexPath))
        }
    }
    
    func getPlaylistForIndexPath(_ indexPath:IndexPath)->Playlist? {
        
        if myPlaylists.count > (indexPath as NSIndexPath).row {
            return myPlaylists[(indexPath as NSIndexPath).row]
        } else {return nil}
    }
    
    
    // MARK - Button Handler
    @IBAction func moreButtonPressed(_ sender: UIButton) {
     
        let playlist = getPlaylistForIndexPath(IndexPath(row: sender.tag, section: 0))
        super.showOptions(musicItem: playlist,options:MusicPopupContainerVC.optionsPlaylists)
    }
    
    
    // MARK: - Navigation
    func goToSongs(_ playlist: Playlist?){
        
        guard let playlist = playlist else {return}
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
        vc.musicItem = playlist
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func createPlaylist() {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
        vc.isNewPlaylist = true
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    //MARK: - Adding tracks to playlist
    func playlistSelectedToAddTrack(playlist:Playlist?) {
        
        guard let song = self.addingTrack else {return}
        guard let playlist = playlist else {return}
        
        //Add track
        self.customLoadingIndicator.startAnimating()
        APIManager.sharedInstance.addTrackToPlaylist(playlist: playlist, song: song, completion: {(success, playlist) in
            
            self.customLoadingIndicator.stopAnimating()
            if (success) {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.showAlert(title: "Uh oh", message: "There was a problem adding the song to this playlist. Please try again")
            }
        })
    }
    
    @objc func didCancelAddingTrack() {
        self.dismiss(animated: true, completion: nil)
    }
}
