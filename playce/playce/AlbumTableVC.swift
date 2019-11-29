//
//  AlbumTableVC.swift
//  playce
//
//  Created by Tys Bradford on 14/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import SDWebImage

class AlbumTableVC: MusicTableVC {

    var myAlbums : [Album] = []
    var myAlbumsTotalDuration = 0
    var myAlbumsSorted : [[Album]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Navbar
        self.title = "Your Albums"
        
        // Table
        self.tableView.tableFooterView = UIView()        
        self.tableView.showsVerticalScrollIndicator = true
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAlbums()
    }
    
    // MARK: - Data
    func updateAlbums() {
        
        if myAlbums.count == 0 {
            self.customLoadingIndicator.startAnimating()
        }
        
        APIManager.sharedInstance.getAlbumsFromBackend { (success, albums) in
            
            self.customLoadingIndicator.stopAnimating()
            self.myAlbums = albums
            if ItunesHandler.sharedInstance.isItunesConnected() {
                self.myAlbums = self.myAlbums + ItunesHandler.sharedInstance.getAllMyAlbums()
            }
            
            if self.myAlbums.count >= self.kMinItemCountForSectionShow {self.sectionIndexVisible = true}
            else {self.sectionIndexVisible = false}
            
            let sorted = MusicTableVC.sortItemsIntoAlphaSections(items: self.myAlbums)
            self.myAlbumsSorted = []
            for itemArray in sorted {
                if let albumArray = itemArray as? [Album] {
                    self.myAlbumsSorted.append(albumArray)
                }
            }
            self.tableView.reloadData()
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.myAlbumsSorted.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.myAlbumsSorted.count {return 1}
        else {return self.myAlbumsSorted[section].count}
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == self.myAlbumsSorted.count {return 105.0}
        else {return 72.0}
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == self.myAlbumsSorted.count {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicFooterCell", for: indexPath) as! MusicFooterCell
            cell.selectionStyle = UITableViewCell.SelectionStyle.none

            let titleString = (myAlbums.count == 1 ? "1 ALBUM" : String(myAlbums.count) +  " ALBUMS")
            cell.titleLabel.text = titleString
            
            let totalDurationMinutes = ((Double(myAlbumsTotalDuration)/1000.0)/60.0)
            cell.subtitleLabel.text = String(format: "%d MINUTES", Int(totalDurationMinutes))
            
            if totalDurationMinutes == 0.0 {
                cell.subtitleLabel.isHidden = true
            } else{
                cell.subtitleLabel.isHidden = false
            }
            return cell
            
        } else {
           
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
            let album = self.getAlbumForIndexPath(indexPath)
            cell.musicItem = album
            cell.moreButton.tag = (indexPath as NSIndexPath).row
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        goToSongs(getAlbumForIndexPath(indexPath))

    }
    
    func getAlbumForIndexPath(_ indexPath:IndexPath)->Album? {
        
        if myAlbumsSorted.count > indexPath.section {
            return myAlbumsSorted[indexPath.section][indexPath.row]
        } else {return nil}
    }
    
    
    // MARK: - Button Handler
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        
        let indexPath = self.getIndexPathFromCellSubview(view:sender)
        if indexPath != nil {
            let album = getAlbumForIndexPath(indexPath!)
            super.showOptions(musicItem: album,options: MusicPopupContainerVC.optionsAlbums)
        }
    }
    
    // MARK: - Navigation
    func goToSongs(_ album: Album?){
        
        guard let album = album else {return}
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
        vc.musicItem = album
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
