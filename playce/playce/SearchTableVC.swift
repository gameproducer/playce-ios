//
//  SearchTableVC.swift
//  playce
//
//  Created by Tys Bradford on 21/02/2017.
//  Copyright © 2017 gigster. All rights reserved.
//

import Foundation

class SearchTableVC : UITableViewController {
    
    var results : [[MusicItem]]?
    var parentVC : DiscoverHomeVC?
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Tableview
        self.tableView.tableFooterView = UIView()
        
        //PlaybackBar UI handling
        self.adjustForPlaybackBar()
    }
    

    //MARK: - View update
    func reloadResults(results:[[MusicItem]]?) {
        self.results = results
        self.tableView.reloadData()
    }
    
    func getProviderForSection(section:Int)->ProviderType{
        if let firstItem = self.getItem(section: section, row: 0) {return firstItem.getProviderType()}
        else {return .none}
    }
    
    func getItem(section:Int,row:Int)->MusicItem? {
        let items = self.getItems(section: section)
        if (items == nil || items?.count == 0) {return nil}
        else if (items?.count)! <= row {return nil}
        else {return items?[row]}
    }
    
    func getItems(section:Int)->[MusicItem]? {
        if self.results == nil {return nil}
        else if (self.results?.count)! <= section {return nil}
        else {return self.results?[section]}
    }
    
    func isResultsEmpty() -> Bool {
        if self.results == nil {return false}
        else { return self.results!.isEmpty}
    }
    
    //MARK: - Table delegate
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.isResultsEmpty() {return 0.0}
        else {return 30.0}
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isResultsEmpty() {return 1}
        let items = self.getItems(section: section)
        if items == nil {return 0}
        else {return (items?.count)!}
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.isResultsEmpty() {return 1}
        if self.results == nil {return 0}
        else {return (self.results?.count)!}
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let labelHeight = 30.0
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 300.0, height: labelHeight))
        let label = UILabel(frame:CGRect(x: 17.0, y: 0.0, width: 300.0, height: labelHeight))
        
        label.font = UIFont(name: ".SFUIText-Semibold", size: 10.0)
        label.textColor = PLStyle.hexStringToUIColor("7F7F7F")
        
        let provider = self.getProviderForSection(section: section)
        if provider != .none {
            label.text = ProviderObject.getProviderNameFromType(provider: provider).uppercased()
        }
        
        view.tag = provider.rawValue
        view.backgroundColor = UIColor.white
        
        //Chevron
        let chevronPadding = 12.0
        let chevron = UIImageView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 4.0, height: 7.0)))
        chevron.image = #imageLiteral(resourceName: "chevron_green_small")
        
        let labelOffsetY = 5.0
        label.sizeToFit()
        label.setHeight(CGFloat(labelHeight))
        label.setOriginY(label.frame.origin.y + CGFloat(labelOffsetY))
        
        chevron.setOriginX(label.frame.origin.x + label.frame.size.width + CGFloat(chevronPadding))
        chevron.alignCenterVertical(label)
        
        //Gesture recogniser
        let gesture = UITapGestureRecognizer(target: self, action: #selector(headerPressed(sender:)))
        view.addGestureRecognizer(gesture)
        
        view.addSubview(label)
        view.addSubview(chevron)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.isResultsEmpty() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "emptyCell", for: indexPath)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
        let musicItem = self.getItem(section: indexPath.section, row: indexPath.row)
        cell.musicItem = musicItem
        cell.moreButton.tag = (indexPath as NSIndexPath).row
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        if self.isResultsEmpty() {return}
        if let item = self.results?[indexPath.section][indexPath.row] {
            self.parentVC?.didSelectItem(item: item)
        }
    }
    

    
    //MARK: - Button Handler
    @IBAction func moreButtonPressed(_ sender: UIButton) {
        
        guard let cell = self.getCellForSubview(view: sender) else {return}
        guard let indexPath = self.tableView.indexPath(for: cell) else {return}
        guard let item = self.results?[indexPath.section][indexPath.row] else {return}
        
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
        let type : ProviderType = ProviderType(rawValue: sender.tag)!
        
        if let parentVC = self.parentVC {
            parentVC.didSelectMoreResult(provider: type)
        }
    }
    
    
    

    
    
    
}
