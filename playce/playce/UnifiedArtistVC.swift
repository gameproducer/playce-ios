//
//  UnifiedArtistVC.swift
//  playce
//
//  Created by Tys Bradford on 3/05/2017.
//  Copyright © 2017 gigster. All rights reserved.
//

import Foundation
import SDWebImage



class UnifiedArtistVC : MusicTableVC {
    
    
    var artist : Artist?
    var providers : [ProviderType]!
    var results : [[String:[MusicItem]]] = []
    var resultsOrder : [[String]] = []
    var selectedProvider : ProviderType?
    let maxTopLevelItems = 3

    var headerView: UIView!

    @IBOutlet weak var heroImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var buttonTab: PLButtonTab!
    @IBOutlet weak var followButton: UIButton!
    
    
    @IBOutlet weak var heroTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var heroBottomConstraint: NSLayoutConstraint!
    
    fileprivate let kHeroViewHeight : CGFloat = 403.0
    fileprivate let kTabViewHeight : CGFloat = 28.0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Providers
        self.providers = UserHandler.sharedInstance.getConnectedProviders()
        if let index = providers.index(of: .iTunes) {
            self.providers.remove(at: index)
        }
        
        self.selectedProvider = artist?.getProviderType()
        
        //Results holders
        for _ in self.providers {
            self.results.append([:])
            self.resultsOrder.append([])
        }
        
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
        
        //Follow button
        self.followButton.layer.borderColor = UIColor.white.cgColor
        self.followButton.layer.borderWidth = 1.0
        self.followButton.layer.cornerRadius = 8.0
        self.followButton.layer.masksToBounds = true
        
    }
    
    deinit {
        self.removeListenersForPlaybackHideShow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Get original results
        if let selectedResults = self.getItemsForSelectedPlatform() {
            if selectedResults.isEmpty {
                if let originalProvider = self.artist?.getProviderType() {
                    self.retrieveResults(provider: originalProvider)
                }
            }
        }
        
        updateFollowButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.buttonTab.subviews.count == 0 {
            self.buttonTab.customInit()
            createTabs()
        }
        
        if self.customLoadingIndicator == nil {
            self.customLoadingIndicator = CustomLoadIndicator(parentView: self.view)
        }
    }
    
    func initHeaderView() {
        
        self.headerView = tableView.tableHeaderView
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

            headerRect.origin.y = yOffset
            headerRect.size.height = -yOffset
        } else if yOffset > -kTabViewHeight{
            headerRect.origin.y = yOffset - (kHeroViewHeight-kTabViewHeight)
        }
        
        headerView.frame = headerRect
    }
    
    func initDetails() {
        
        guard let artist = self.artist else {return}
        
        titleLabel.text = artist.name
        setTruncatedTitle(artist.name)
        
        //Set image
        if let imgURL = artist.getImageURL() {
            
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

    func createTabs() {
        
        //For all connected providers add a button tab
        for provider in self.providers {
            
            let providerName = ProviderObject.getProviderNameFromType(provider: provider)
            let button = buttonTab.addButton(providerName.uppercased())
            button.tag = provider.rawValue
            button.addTarget(self, action: #selector(tabButtonPressed(_:)), for: .touchUpInside)
            
            //Set initial button selection
            if let artist = self.artist {
                if artist.getProviderType() == provider {
                    button.isSelected = true
                    self.buttonTab.moveInidicatorToButton(button, animated: false)
                }
            }
        }
    }
    
    
    
    //MARK: - Data Retrieve
    func retrieveResults(provider:ProviderType) {
        
        //Check if type is original
        let originalType = self.artist?.getProviderType()
        guard let indexOfProvider = self.getIndexOfProvider(provider: provider) else {return}
        
        if provider == originalType {
            guard let artistID = self.artist?.externalId else {return}
            self.customLoadingIndicator.startAnimating()
            APIManager.sharedInstance.artistSearch(provider: provider, artistID: artistID, completion: { (success,results,sortOrder) in
                self.customLoadingIndicator.stopAnimating()
                if let results = results {
                    self.results[indexOfProvider] = results
                }
                
                if let sortOrder = sortOrder {
                    self.resultsOrder[indexOfProvider] = sortOrder
                }
                
                self.tableView.reloadData()
            })
        } else {
            guard let artistName = self.artist?.name else {return}
            self.customLoadingIndicator.startAnimating()
            APIManager.sharedInstance.artistSearchName(provider: provider, artistName: artistName, completion: { (success,results,sortOrder) in
                self.customLoadingIndicator.stopAnimating()
                if let results = results {
                    self.results[indexOfProvider] = results
                }
                
                if let sortOrder = sortOrder {
                    self.resultsOrder[indexOfProvider] = sortOrder
                }
                
                self.tableView.reloadData()
            })
        }
    }
    
    
    //MARK: - Data Helpers
    func getItemsForSelectedPlatform() -> [String:[MusicItem]]? {
        guard let provider = self.selectedProvider else {return nil}
        guard let resultIndex = self.getIndexOfProvider(provider: provider) else {return nil}
        let resultDict = self.results[resultIndex]
        return resultDict
    }
    
    func getSectionTitlesForSelectedPlatform() -> [String]? {
        guard let provider = self.selectedProvider else {return nil}
        guard let resultIndex = self.getIndexOfProvider(provider: provider) else {return nil}
        guard let resultsDict = self.getItemsForSelectedPlatform() else {return nil}
        if resultIndex < self.resultsOrder.count {
            let order = resultsOrder[resultIndex]
            if order.isEmpty {return resultsDict.keys.sorted()}
            else {return resultsOrder[resultIndex]}
        } else {
            return resultsDict.keys.sorted()
        }
    }
    
    func getItems(sectionIndex:Int) -> [MusicItem]? {
        guard let resultsDict = self.getItemsForSelectedPlatform() else {return nil}
        guard let keys = self.getSectionTitlesForSelectedPlatform() else {return nil}
        if sectionIndex < keys.count {return resultsDict[keys[sectionIndex]]}
        else {return nil}
    }
    
    func getIndexOfProvider(provider:ProviderType) -> Int? {
        for i in 0..<self.providers.count {
            let prov = self.providers[i]
            if prov == provider {return i}
        }
        return nil
    }
    
    
    
    //MARK: - TableView Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        if let sections = self.getSectionTitlesForSelectedPlatform() {return sections.count}
        else {return 0}
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let labelHeight = 30.0
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 300.0, height: labelHeight))
        let label = UILabel(frame:CGRect(x: 17.0, y: 0.0, width: 300.0, height: labelHeight))
        
        label.font = UIFont(name: ".SFUIText-Semibold", size: 10.0)
        label.textColor = PLStyle.hexStringToUIColor("7F7F7F")
        
        if let titles = self.getSectionTitlesForSelectedPlatform() {
            let sectionTitle = titles[section]
            label.text = self.formatHeaderTitle(title: sectionTitle)
        }
        
        view.tag = section
        view.backgroundColor = UIColor.white
        
        //Chevron
        let chevronPadding = 3.0
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
    
    func createHeaderCell(section:Int) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "header")
        cell.addSubview(self.createHeaderView(section: section))
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        return cell
    }
    
    func createHeaderView(section:Int) -> UIView {
        
        let labelHeight = 30.0
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 300.0, height: labelHeight))
        let label = UILabel(frame:CGRect(x: 17.0, y: 0.0, width: 300.0, height: labelHeight))
        
        label.font = UIFont(name: ".SFUIText-Semibold", size: 10.0)
        label.textColor = PLStyle.hexStringToUIColor("7F7F7F")
        
        if let titles = self.getSectionTitlesForSelectedPlatform() {
            let sectionTitle = titles[section]
            label.text = self.formatHeaderTitle(title: sectionTitle)
        }
        
        view.tag = section
        view.backgroundColor = UIColor.white
        
        //Chevron
        let chevronPadding = 3.0
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
    
    func formatHeaderTitle(title:String) -> String {
        
        //Replace underscores with spaces
        //Make Word Case
        var finalString = title
        finalString = finalString.replacingOccurrences(of: "_", with: " ")
        finalString = finalString.uppercased()
        return finalString
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let items = self.getItems(sectionIndex: section) {
            if items.count > 0 {return min(items.count,maxTopLevelItems)+1}
            else {return 0}
        }
        else {return 0}
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let items = self.getItems(sectionIndex: indexPath.section) {
            if items.count > 0 {
                if indexPath.row == 0 {return 30.0}
                else {return 72.0}
            } else {return 0.0}
        }
        else {return 0.0}
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //Section header cell
        if indexPath.row == 0 {
            return self.createHeaderCell(section: indexPath.section)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "musicItemCell", for: indexPath) as! MusicItemCell
        
        //Set cell
        guard let items = self.getItems(sectionIndex: indexPath.section) else {return cell}
        cell.musicItem = items[(indexPath as NSIndexPath).row-1]
        
        //If album show the track number not the track image
        let numberLabel = cell.viewWithTag(100) as? UILabel
        
        cell.thumbnail?.isHidden = false
        if numberLabel != nil {
            numberLabel?.isHidden = true
        }

        //More button
        cell.moreButton.tag = indexPath.row
        
        return cell
    }
    
    
    //MARK: - Table Actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //Get selected item
        if indexPath.row > 0 {
            
            if let items = self.getItems(sectionIndex: indexPath.section) {
                let item = items[indexPath.row-1]
                self.didSelectItem(item:item)
            }
        }
    }
    

    //MARK: - Button Handler
    @IBAction func moreButtonPressed(_ sender: UIView) {
        guard let item = self.artist else {return}
        let options = MusicPopupContainerVC.optionsArtist
        showOptions(musicItem:item,options: options)
    }
    
    @IBAction func itemMoreButtonPressed(_ sender: UIButton) {
        
        guard let cell = self.getCellForSubview(view: sender) else {return}
        guard let indexPath = self.tableView.indexPath(for: cell) else {return}
        guard let items = self.getItems(sectionIndex: indexPath.section) else {return}
        let item = items[indexPath.row-1]
        
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
        
        self.showOptions(musicItem: item,options: options)
    }
    
    func getCellForSubview(view:UIView) -> UITableViewCell? {
        
        var view = view
        while let parentView = view.superview {
            if parentView is UITableViewCell {return parentView as? UITableViewCell}
            view = parentView
        }
        return nil
    }

    
    
    @objc func tabButtonPressed(_ button: UIButton) {
        
        let providerType : ProviderType = ProviderType(rawValue: button.tag)!
        
        //Check if selection is current tab -> do nothing
        if self.selectedProvider == providerType {return}
        self.selectedProvider = providerType
        self.scrollToTop()

        //Get results for provider
        //If none exist - find them and add to results array
        if let providerIndex = self.getIndexOfProvider(provider: providerType) {
            let providerResults = self.results[providerIndex]
            if providerResults.count > 0 {
                self.tableView.reloadData()
                return
            }
        }
        
        self.retrieveResults(provider: providerType)
    }
    
    func scrollToTop() {
        self.tableView.setContentOffset(CGPoint(x:0,y:-kHeroViewHeight), animated: true)
    }
    
    
    @objc func headerPressed(sender:UITapGestureRecognizer) {
        
        let sender:UIView = sender.view!
        let section = sender.tag
        let items = self.getItems(sectionIndex: section)
        let sectionTitles = self.getSectionTitlesForSelectedPlatform()
        
        var title : String?
        if let headerName = sectionTitles?[section] {
            title = self.formatHeaderTitle(title: headerName).capitalized
        }
        
        self.goToExtendedResults(results:items,title:title)
    }
    
    
    //MARK: - Scrollview Delegate
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
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
            vc.musicItem = album
            vc.isSearchDetail = true
            self.navigationController?.pushViewController(vc, animated: true)
            
        } else if let playlist = item as? Playlist {
            //Go to detail
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MusicDetailTableVC") as! MusicDetailTableVC
            vc.musicItem = playlist
            vc.isSearchDetail = true
            self.navigationController?.pushViewController(vc, animated: true)
            
        } else if let artist = item as? Artist {
            //Go to unified artist
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "UnifiedArtistVC") as! UnifiedArtistVC
            vc.artist = artist
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func goToExtendedResults(results:[MusicItem]?,title:String?) {
        let extendedSearchVC = self.storyboard?.instantiateViewController(withIdentifier: "ExtendedSearchTableVC") as! ExtendedSearchTableVC
        extendedSearchVC.results = results
        extendedSearchVC.customTitle = title
        extendedSearchVC.isSearchDetail = true
        self.navigationController?.pushViewController(extendedSearchVC, animated: true)
    }
    
    
    //MARK: - Follow Artist
    func updateFollowButton() {
        guard let artist = self.artist else {return}
        if LibraryHandler.sharedInstance.doesItemExistInLibrary(item: artist) {
            self.followButton.setTitle("Unfollow", for: .normal)
        } else {
            self.followButton.setTitle("Follow", for: .normal)
        }
    }
    
    @IBAction func followButtonPressed(_ sender: Any) {
        
        guard let artist = self.artist else {return}
        if LibraryHandler.sharedInstance.doesItemExistInLibrary(item: artist) {
            LibraryHandler.sharedInstance.removeItemFromLibrary(item: artist, completion: { (success) in
                if success {
                    self.updateFollowButton()
                } else {
                    self.showAlert(title: "Warning", message: "Could not unfollow this artist at this time. Please try again later.")
                }
            })
        } else {
            LibraryHandler.sharedInstance.addItemToLibrary(item: artist, completion: { (success) in
                if success {
                    self.updateFollowButton()
                    self.artist = artist
                    
                } else {
                    self.showAlert(title: "Warning", message: "Could not follow this artist at this time. Please try again later.")
                }
            })
        }
    }
    
}
