//
//  DiscoveryTableVC.swift
//  playce
//
//  Created by Tys Bradford on 23/08/2017.
//  Copyright © 2017 gigster. All rights reserved.
//

import UIKit

class DiscoveryTableVC: UITableViewController {
    
    var results : [ProviderType:[(String,[MusicItem])]]?
    var parentVC : DiscoverHomeVC?
    var selectedProvider : ProviderType = .none
    let maxItemsShown : Int = 5

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Tableview
        self.tableView.tableFooterView = UIView()
        
        //PlaybackBar UI handling
        self.adjustForPlaybackBar()
    }
    
    
    //MARK: - View update
    func getSelectedItemCollections() -> [(String,[MusicItem])]? {
        return self.results?[self.selectedProvider]
    }
    
    func getSelectedItemCollection(section:Int) -> (String,[MusicItem])? {
        return getSelectedItemCollections()?[section]
    }
    
    func getItemForIndexPath(indexPath:IndexPath) -> MusicItem? {
        guard let collection = self.getSelectedItemCollection(section: indexPath.section) else {return nil}
        let items = collection.1
        if items.count > indexPath.row {return items[indexPath.row]}
        else {return nil}
    }
    
    func getItemsForSection(section:Int) -> [MusicItem]? {
        guard let collection = self.getSelectedItemCollection(section: section) else {return nil}
        return collection.1
    }
    
    func isResultsEmpty() -> Bool {
        if self.results == nil {return false}
        if self.results!.isEmpty {return false}
        else {
            
            let itemCollection = self.getSelectedItemCollections()
            if itemCollection == nil {return true}
            else {return false}
        }
    }
    
    //MARK: - Table delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if self.isResultsEmpty() {return 100.0}
        else if (self.selectedProvider == .spotify || self.selectedProvider == .deezer || self.selectedProvider == .appleMusic) {return 194.0}
        else if self.selectedProvider == .soundCloud {return 234.0}
        else if self.selectedProvider == .youtube {return 274.0}
        else {return 72.0}
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.isResultsEmpty() {return 0.0}
        else {return getHeaderHeight(section: section)}
    }
    
    func getHeaderHeight(section:Int) -> CGFloat {
        if section == 0 {return 37.0}
        else {return 49.0}
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isResultsEmpty() {return 1}
        if (self.selectedProvider == .spotify || self.selectedProvider == .deezer || self.selectedProvider == .appleMusic) {return 1}
        guard let collection = self.getSelectedItemCollection(section: section) else {return 0}
        let items = collection.1
        return items.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.isResultsEmpty() {return 1}
        guard let collections = getSelectedItemCollections() else {return 0}
        return collections.count
    }
    
    func getSubtitleFromTitle(title:String?) -> String {
        
        guard let title = title else {return ""}
        
        var updatedString = title.replacingOccurrences(of: "_", with: " ")
        updatedString = updatedString.uppercased()
        return updatedString
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerHeight = getHeaderHeight(section: section)
        let labelHeight : CGFloat = 12.0
        let labelYPos = headerHeight - labelHeight - 12.0
        
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 300.0, height: headerHeight))
        let label = UILabel(frame:CGRect(x: 17.0, y: labelYPos, width: 300.0, height: labelHeight))
        
        label.font = UIFont(name: ".SFUIText-Semibold", size: 10.0)
        label.textColor = PLStyle.hexStringToUIColor("7F7F7F")
        
        let collection = self.getSelectedItemCollection(section: section)
        let originalTitle = collection?.0
        label.text =  getSubtitleFromTitle(title:originalTitle)
        view.tag = section
        view.backgroundColor = UIColor.white
        
        label.sizeToFit()
        view.addSubview(label)

        //Chevron
        //Only have chevron for Spotify + Deezer tables
        if (self.selectedProvider == .spotify || self.selectedProvider == .deezer || self.selectedProvider == .appleMusic) {
            let chevronPadding = 12.0
            let chevron = UIImageView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 4.0, height: 7.0)))
            chevron.image = #imageLiteral(resourceName: "chevron_green_small")
            
            chevron.setOriginX(label.frame.origin.x + label.frame.size.width + CGFloat(chevronPadding))
            chevron.alignCenterVertical(label)
            
            //Gesture recogniser
            let gesture = UITapGestureRecognizer(target: self, action: #selector(headerPressed(sender:)))
            view.addGestureRecognizer(gesture)
            
            view.addSubview(chevron)
        }

        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (self.selectedProvider == .none) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath)
            let label = cell.viewWithTag(100) as? UILabel
            //label?.text = "There was an unexpected error. Please check your connected providers and try again"
            label?.text = ""
            return cell
        }
        
        if (!UserHandler.sharedInstance.isProviderConnected(provider: self.selectedProvider) && self.selectedProvider != .none) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath)
            let label = cell.viewWithTag(100) as? UILabel
            label?.text = "You have not connected this provider yet"
            return cell
        }
        
        if self.isResultsEmpty() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath)
            let label = cell.viewWithTag(100) as? UILabel
            label?.text = "No Discovery items found"
            return cell
        }
        else if (selectedProvider == .spotify || selectedProvider == .deezer || self.selectedProvider == .appleMusic) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "discoveryCellHoriz", for: indexPath) as! DiscoverHorizontalCell
            
            cell.discoverHomeVC = self.parentVC
            if let items = self.getItemsForSection(section: indexPath.section) {
                cell.setItems(items: items)
            }
            return cell
        }
        else if (selectedProvider == .soundCloud) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "discoveryCellSoundcloud", for: indexPath) as! DiscoverSoundcloudCell
            if let musicItem = self.getItemForIndexPath(indexPath: indexPath) {
                cell.setItem(item: musicItem)
            }
            return cell
        }
        else if (selectedProvider == .youtube) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "discoveryCellYoutube", for: indexPath) as! DiscoverYoutubeCell
            if let musicItem = self.getItemForIndexPath(indexPath: indexPath) {
                cell.setItem(item: musicItem)
            }
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
            let musicItem = self.getItemForIndexPath(indexPath: indexPath)
            cell.musicItem = musicItem
            cell.moreButton.tag = (indexPath as NSIndexPath).row
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if self.isResultsEmpty() {return}
        if self.selectedProvider == .spotify || self.selectedProvider == .deezer || self.selectedProvider == .appleMusic {return}
        if let item = self.getItemForIndexPath(indexPath: indexPath) {
            
            if let list = self.getItemsForSection(section: indexPath.section) as? [Song] {
                let song = item as! Song
                self.parentVC?.didSelectSongFromList(song: song, list: list)
            } else {
                self.parentVC?.didSelectItem(item: item)
            }
        }
    }
    
    
    //MARK: - Button Handler
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        
        guard let cell = self.getCellForSubview(view: sender) else {return}
        guard let indexPath = self.tableView.indexPath(for: cell) else {return}
        guard let item = self.getItemForIndexPath(indexPath: indexPath) else {return}
        
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
        
        self.parentVC?.showOptions(musicItem: item,options: options)
    }
    
    func getCellForSubview(view:UIView) -> UITableViewCell? {
        
        var view = view
        while let parentView = view.superview {
            if parentView is UITableViewCell {return parentView as? UITableViewCell}
            view = parentView
        }
        
        return nil
    }
    
    
    
    //MARK: - Gesture Handler
    @objc func headerPressed(sender:UITapGestureRecognizer) {
        
        let sender:UIView = sender.view!
        let section : Int = sender.tag
        
        let collection = self.getSelectedItemCollection(section: section)
        let originalTitle = collection?.0
        
        let sectionName = self.getSubtitleFromTitle(title: originalTitle)
        let items = collection?.1
        
        if let parentVC = self.parentVC {
            parentVC.didSelectDiscoverySection(sectionName: sectionName, items: items)
        }
    }
}
