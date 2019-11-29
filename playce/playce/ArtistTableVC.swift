//
//  ArtistTableVC.swift
//  playce
//
//  Created by Tys Bradford on 14/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class ArtistTableVC : MusicTableVC {

    var myArtists : [Artist] = []
    var myArtistsSorted : [[Artist]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Navbar
        self.title = "Your Artists"
        
        // Table
        self.tableView.showsVerticalScrollIndicator = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateArtists()
    }
    
    // MARK: - Data
    func updateArtists() {
        
        if myArtists.count == 0 {
            self.customLoadingIndicator.startAnimating()
        }
        
        APIManager.sharedInstance.getArtistsFromBackend { (success, artists) in
            
            self.customLoadingIndicator.stopAnimating()
            self.myArtists = artists
            
            if ItunesHandler.sharedInstance.isItunesConnected() {
                self.myArtists = self.myArtists + ItunesHandler.sharedInstance.getAllMyArtists()
            }
            
            if self.myArtists.count >= self.kMinItemCountForSectionShow {self.sectionIndexVisible = true}
            else {self.sectionIndexVisible = false}
            
            let sorted = MusicTableVC.sortItemsIntoAlphaSections(items: self.myArtists)
            self.myArtistsSorted = []
            for itemArray in sorted {
                if let artistArray = itemArray as? [Artist] {
                    self.myArtistsSorted.append(artistArray)
                }
            }
        self.tableView.reloadData()
        }
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.myArtistsSorted.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.myArtistsSorted.count {return 1}
        else {return self.myArtistsSorted[section].count}
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == self.myArtistsSorted.count {return 105.0}
        else {return 72.0}
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == self.myArtistsSorted.count {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicFooterCell", for: indexPath) as! MusicFooterCell
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            
            let titleString = (myArtists.count == 1 ? "1 ARTIST" : String(myArtists.count) +  " ARTIST")
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
            let artist = self.getArtistForIndexPath(indexPath)
            cell.musicItem = artist
            cell.moreButton.tag = (indexPath as NSIndexPath).row
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if let artist = self.getArtistForIndexPath(indexPath) {
            
            //If already have saved track for this artist then go to these else go to UA
            if artist.getNumberOfSongs() > 0 {
                self.goToSongs(artist)
            } else {
                
                //Check if this is an Itunes artist that has not been synced
                if (artist.isLocal) {
                    
                    let message = "It appears this iTunes Artist has no tracks synced to this device. You can sync tracks locally using the Music app.";
                    let ac = UIAlertController(title: "Uh oh", message: message, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    ac.addAction(okAction)
                    self.present(ac, animated: true, completion: nil)
                } else {
                    self.goToArtistDetail(artist: artist)
                }
            }
        }
    }
    
    func getArtistForIndexPath(_ indexPath:IndexPath)->Artist? {
        
        if myArtistsSorted.count > indexPath.section {
            return myArtistsSorted[indexPath.section][indexPath.row]
        } else {return nil}
    }
    
    
    // MARK - Button Handler
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        
        let indexPath = self.getIndexPathFromCellSubview(view:sender)
        if indexPath != nil {
            let artist = getArtistForIndexPath(indexPath!)
            super.showOptions(musicItem:artist,options:MusicPopupContainerVC.optionsArtist)
        }
    }
    
    
    // MARK: - Navigation
    func goToSongs(_ artist: Artist?){
        
        guard let artist = artist else {return}
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
        vc.musicItem = artist
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goToArtistDetail(artist:Artist) {
        
        //Go to unified artist
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "UnifiedArtistVC") as! UnifiedArtistVC
        vc.artist = artist
        self.navigationController?.pushViewController(vc, animated: true)
    }

}
