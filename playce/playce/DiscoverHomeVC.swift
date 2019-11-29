//
//  DiscoverHomeVC.swift
//  playce
//
//  Created by Tys Bradford on 14/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class DiscoverHomeVC: UIViewController {

    var songsButton : UIButton!
    var artistsButton : UIButton!
    var albumsButton : UIButton!
    var playlistsButton : UIButton!
    
    var spotifyButton : UIButton?
    var soundcloudButton : UIButton?
    var deezerButton : UIButton?
    var youtubeButton : UIButton?
    var appleMusicButton : UIButton?

    var searchTable : SearchTableVC!
    var discoveryTable : DiscoveryTableVC!
    var customLoadingIndicator : CustomLoadIndicator?

    var selectedList : [ProviderType:[MusicItem]] = [:]
    var songsList : [ProviderType:[Song]] = [:]
    var albumList : [ProviderType:[Album]] = [:]
    var artistList : [ProviderType:[Artist]] = [:]
    var playlistList : [ProviderType:[Playlist]] = [:]
    var currentSearchString : String?
    
    let discoverySortOrder : [ProviderType] = [.spotify, .deezer, .soundCloud, .youtube, .appleMusic]
    var selectedDiscoverySection : ProviderType = .none
    var selectedSection : MusicItemType = .track
    
    let searchFullCount = 50
    let searchSmallCount = 3
    
    var discoverCollection : [ProviderType:[(String,[MusicItem])]] = [:]

    var optionsVC : MusicPopupContainerVC?
    var shouldShowSearch = false;
    static var existingProviders : [ProviderType] = []

    
    @IBOutlet weak var discoverButtonTabView: PLButtonTab!
    @IBOutlet weak var searchButtonTabView: PLButtonTab!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Navbar
        self.title = "Discovery"
        
        //Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(searchDidCancel), name: Notification.Name(rawValue: PLNavController.kPLSearchBarDidCancelNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateProviders), name: Notification.Name(APIManager.providersWereUpdatedNotification), object: nil)
        
        //Set discovery mode initial
        for provider in self.discoverySortOrder {
            
            if UserHandler.sharedInstance.isProviderConnected(provider: provider) {
                self.selectedDiscoverySection = provider
                break
            }
        }
        
        //Discovery Table
        self.discoveryTable = self.storyboard!.instantiateViewController(withIdentifier: "DiscoveryTableVC") as! DiscoveryTableVC
        self.addChild(self.discoveryTable)
        self.discoveryTable.didMove(toParent: self)
        self.view.addSubview(self.discoveryTable.view)
        
        self.setSubViewConstraints()
        self.discoveryTable.selectedProvider = self.selectedDiscoverySection
        self.discoveryTable.parentVC = self
        
        //Coming in from search mode
        if shouldShowSearch == true {
            hideDiscovery()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setSubViewConstraints() {
        
        self.discoveryTable.view.translatesAutoresizingMaskIntoConstraints = false
        
        if searchTable == nil {
            return
        }
        
        self.view.addConstraint(NSLayoutConstraint(item: self.discoveryTable.view, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.searchTable.view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.discoveryTable.view, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.searchTable.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1.0, constant: 0.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.discoveryTable.view, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.searchTable.view, attribute: NSLayoutConstraint.Attribute.right, multiplier: 1.0, constant: 0.0))
        self.view.addConstraint(NSLayoutConstraint(item: self.discoveryTable.view, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.searchTable.view, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0))
        
    }
    
    func setTitleDiscovery() {
        self.title = "Discovery"
    }
    
    func setTitleNone() {
        self.title = ""
    }
    
    func setTitleSearch() {
        self.title = "Search"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.navigationController as? PLNavController)?.showSearchButton(true)
        
        //Check if active search
        if (self.currentSearchString != nil && self.currentSearchString!.count > 0) {
            //Show search field
            if let navcontroller = self.navigationController as? PLNavController {
                self.setTitleNone()
                navcontroller.showSearchBar(true)
                navcontroller.resignSearchBarResponder()
            }
        }
        
        //Update discovery items
        self.discoveryTable.results = self.discoverCollection
        self.discoveryTable.tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        //Discover content + buttons
        self.updateProviders()
        
        //Search buttons
        if self.searchButtonTabView.subviews.count == 0 {
            self.searchButtonTabView.customInit()
            createSearchPanelButtons()
        }
        
        if self.customLoadingIndicator == nil {
            self.customLoadingIndicator = CustomLoadIndicator(parentView: self.view)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "searchTableEmbedSegue" {
            self.searchTable = segue.destination as? SearchTableVC
            self.searchTable.parentVC = self
        }
    }
    
    
    func createSearchPanelButtons(){
        
        songsButton = searchButtonTabView.addButton("SONGS")
        artistsButton = searchButtonTabView.addButton("ARTISTS")
        albumsButton = searchButtonTabView.addButton("ALBUMS")
        playlistsButton = searchButtonTabView.addButton("PLAYLISTS")
        
        songsButton.addTarget(self, action: #selector(DiscoverHomeVC.tabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        artistsButton.addTarget(self, action: #selector(DiscoverHomeVC.tabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        albumsButton.addTarget(self, action: #selector(DiscoverHomeVC.tabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        playlistsButton.addTarget(self, action: #selector(DiscoverHomeVC.tabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        
        searchButtonTabView.moveInidicatorToButton(songsButton, animated: false)
        songsButton.isSelected = true
    }
    
    func updateDiscoveryTabButtons() {
        
        //Reset existing buttons and recreate
        self.discoverButtonTabView.clearAll()
        self.discoverButtonTabView.customInit()
        createDiscoveryPanelButtons()
    }
    
    func createDiscoveryPanelButtons() {
    
        var firstButton : UIButton?
        
        if UserHandler.sharedInstance.isProviderConnected(provider: .spotify) {
            spotifyButton = discoverButtonTabView.addButton("SPOTIFY")
            spotifyButton!.addTarget(self, action: #selector(DiscoverHomeVC.discoveryTabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
            
            firstButton = spotifyButton
        }
        
        if (UserHandler.sharedInstance.isProviderConnected(provider: .appleMusic)) {
            appleMusicButton = discoverButtonTabView.addButton("APPLE MUSIC")
            appleMusicButton!.addTarget(self, action: #selector(DiscoverHomeVC.discoveryTabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
            
            if firstButton == nil {firstButton = appleMusicButton}
        }
        
        if (UserHandler.sharedInstance.isProviderConnected(provider: .deezer)) {
            deezerButton = discoverButtonTabView.addButton("DEEZER")
            deezerButton!.addTarget(self, action: #selector(DiscoverHomeVC.discoveryTabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
            
            if firstButton == nil {firstButton = deezerButton}
        }
        
        if (UserHandler.sharedInstance.isProviderConnected(provider: .soundCloud)) {
            soundcloudButton = discoverButtonTabView.addButton("SOUNDCLOUD")
            soundcloudButton!.addTarget(self, action: #selector(DiscoverHomeVC.discoveryTabButtonPressed(_:)), for: UIControl.Event.touchUpInside)
            
            if firstButton == nil {firstButton = soundcloudButton}
        }
        
        if (UserHandler.sharedInstance.isProviderConnected(provider: .youtube)) {
            youtubeButton = discoverButtonTabView.addButton("YOUTUBE")
            youtubeButton!.addTarget(self, action: #selector(DiscoverHomeVC.discoveryTabButtonPressed(_:)), for: UIControl.Event.touchUpInside)

            if firstButton == nil {firstButton = youtubeButton}
        }
        
        if let selectButton = firstButton {
            discoverButtonTabView.moveInidicatorToButton(selectButton, animated: false)
            selectButton.isSelected = true
        }
    }
    
    
    // MARK: - Button Handler
    @objc func tabButtonPressed(_ button: UIButton) {
        
        switch button {
        case songsButton:
            self.selectedList = self.songsList
            self.selectedSection = .track
            break
        case artistsButton:
            self.selectedList = self.artistList
            self.selectedSection = .artist
            break
        case albumsButton:
            self.selectedList = self.albumList
            self.selectedSection = .album
            break
        case playlistsButton:
            self.selectedList = self.playlistList
            self.selectedSection = .playlist
            break
        default:
            
            break
        }
        
        //SEARCH if no results for section
        guard let searchString = self.getSearchString() else {return}
        if self.selectedList.isEmpty {
            self.performSearch(searchString: searchString)
        }
    }
    
    @objc func discoveryTabButtonPressed(_ button: UIButton) {
        
        if (spotifyButton != nil && button == spotifyButton) {
            self.selectedDiscoverySection = .spotify
        } else if (soundcloudButton != nil && button == soundcloudButton) {
            self.selectedDiscoverySection = .soundCloud
        } else if (deezerButton != nil && button == deezerButton) {
            self.selectedDiscoverySection = .deezer
        } else if (youtubeButton != nil && button == youtubeButton) {
            self.selectedDiscoverySection = .youtube
        } else if (appleMusicButton != nil && button == appleMusicButton) {
            self.selectedDiscoverySection = .appleMusic
        }
        
        self.discoveryTable.selectedProvider = self.selectedDiscoverySection
        self.discoveryTable.tableView.reloadData()
        
        if self.discoveryTable.results != nil && self.discoveryTable.results!.count > 0 {
            self.discoveryTable.tableView.scrollToRow(at: IndexPath(item:0,section:0), at: .top, animated:false)
        }
    }

    
    
    // MARK: - Discovery
    func showDiscovery() {
        self.clearSearch()
        self.updateResultsTable()
        self.setTitleDiscovery()
        self.discoveryTable.view.isHidden = false
        self.discoverButtonTabView.isHidden = false;
    }
    
    func hideDiscovery() {
        self.discoveryTable.view.isHidden = true
        self.discoverButtonTabView.isHidden = true;
    }

    @objc func updateProviders() {
        let providers = UserHandler.sharedInstance.getConnectedProviders()
        if self.discoverButtonTabView.subviews.count == 0 || !providers.elementsEqual(DiscoverHomeVC.existingProviders) {
            
            updateDiscoveryTabButtons()
            DiscoverHomeVC.existingProviders = providers
            self.updateDiscoveryCollection(firstPass: true)
        }
    }
    
    func updateDiscoveryCollection(firstPass:Bool) {
        
        self.discoveryTable.results = self.discoverCollection
        
        //Get all discovery items for connected platforms
        //Update the discovery table every time results come through

        var connectedProviders = UserHandler.sharedInstance.getConnectedProviders()
        if (connectedProviders.count == 0 && firstPass) {
            APIManager.sharedInstance.getAllProviders(completion: { (success, providers) in
                self.updateDiscoveryCollection(firstPass: false)
            })
            return;
        }
        
        //Remove iTunes from search for now
        let itunesIndex = connectedProviders.index(of: .iTunes)
        if itunesIndex != nil {connectedProviders.remove(at: itunesIndex!)}
        
        if connectedProviders.count == 0 {self.showNoProvidersAlert()}
        else {
            
            for provider in connectedProviders {
                
                APIManager.sharedInstance.getDiscoveryItems(provider: provider, completion: { (success, collections) in
                    
                    if success && collections != nil {
                        
                        for collection in collections! {
                            
                            let collectionType = collection.0
                            let collectionTitle = collection.1
                            let collectionItems = collection.2
                            
                            let newTuple = (collectionTitle,collectionItems)
                            let existingCollections = self.discoverCollection[provider]
                            if existingCollections == nil {
                                let newArr = [newTuple]
                                self.discoverCollection[provider] = newArr
                            } else {
                                let newArr = existingCollections! + [newTuple]
                                self.discoverCollection[provider] = newArr
                            }
                        }
                        
                        self.discoveryTable.results = self.discoverCollection
                        self.discoveryTable.tableView.reloadData()
                    }
                })
            }
        }
    }
    
    func didSelectDiscoverySection(sectionName:String,items:[MusicItem]?) {
        
        let extendedSearchVC = self.storyboard?.instantiateViewController(withIdentifier: "ExtendedSearchTableVC") as! ExtendedSearchTableVC
        extendedSearchVC.customTitle = sectionName
        extendedSearchVC.results = items
        self.navigationController?.pushViewController(extendedSearchVC, animated: true)
    }
    
    
    // MARK: - Search
    func clearSearch() {
        self.songsList = [:]
        self.albumList = [:]
        self.artistList = [:]
        self.playlistList = [:]
    }
    
    func getSearchString() -> String? {
        if let navController = self.navigationController as? PLNavController {
            return navController.searchBar.text
        } else {return nil}
    }
    
    func getSelectedSection()->MusicItemType {
        return self.selectedSection
    }
    
    @objc func searchDidCancel() {
        self.currentSearchString = nil
        self.customLoadingIndicator?.stopAnimating()
        self.showDiscovery()
    }
    
    func performSearch(searchString:String?) {
        
        self.currentSearchString = searchString
        
        //If string is nil then revert to discovery mode
        if (searchString == nil || ((searchString?.count) == 0)) {
            self.showDiscovery()
            return
        }
        
        //Hide discovery
        if self.discoveryTable != nil {
            self.hideDiscovery()
        }
        
        //Reload search results with new query
        self.clearSearch()
        
        self.customLoadingIndicator?.startAnimating()
        let selectedSection = self.getSelectedSection()
        switch selectedSection {
        case .track:
            self.searchSongs(searchString: searchString!)
            break
        case .artist:
            self.searchArtists(searchString: searchString!)
            break
        case .album:
            self.searchAlbums(searchString: searchString!)
            break
        case .playlist:
            self.searchPlaylists(searchString: searchString!)
            break
        default:
            break
        }
    }
    
    func searchSongs(searchString:String) {
        let section = MusicItemType.track
        self.getSearchResultsForConnectedProviders(searchString: searchString, section: section)
    }
    
    func searchArtists(searchString:String) {
        let section = MusicItemType.artist
        self.getSearchResultsForConnectedProviders(searchString: searchString, section: section)
    }
    
    func searchAlbums(searchString:String) {
        let section = MusicItemType.album
        self.getSearchResultsForConnectedProviders(searchString: searchString, section: section)
    }
    
    func searchPlaylists(searchString:String) {
        let section = MusicItemType.playlist
        self.getSearchResultsForConnectedProviders(searchString: searchString, section: section)
    }
    
    func getSearchResultsForConnectedProviders(searchString:String,section:MusicItemType) {
        
        var connectedProviders = UserHandler.sharedInstance.getConnectedProviders()
        
        //Remove iTunes from search for now
        let itunesIndex = connectedProviders.index(of: .iTunes)
        if itunesIndex != nil {connectedProviders.remove(at: itunesIndex!)}
        
        if connectedProviders.count == 0 {self.showNoProvidersAlert()}
        else {
            
            for provider in connectedProviders {
                
                APIManager.sharedInstance.searchForItems(searchString: searchString, provider: provider, resultType: section, results: self.searchFullCount, pageToken: nil, completion: { (success, results) in
                    
                    self.customLoadingIndicator?.stopAnimating()
                    if (searchString == self.currentSearchString) {
                        var finalResults = results
                        if results == nil {finalResults = []}
                        self.didGetSearchResults(provider: provider, results: finalResults, section:section)
                    }
                })
            }
        }
    }
    
    func showNoProvidersAlert() {
        
        //Check if this is the currently active VC
        if viewIfLoaded?.window == nil {return}
        
        self.customLoadingIndicator?.stopAnimating()
        let ac = UIAlertController(title: "Uh oh", message: "You do not have any connected providers to search through. Please connect some via the settings screen and try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        ac.addAction(okAction)
        self.present(ac, animated: true, completion: nil)
    }
    
    func didGetSearchResults(provider:ProviderType,results:[MusicItem]?, section:MusicItemType){
                
        //Add to results holder
        switch section {
        case .track:
            self.songsList[provider] = results as! [Song]?
            break
        case .artist:
            self.artistList[provider] = results as! [Artist]?
            break
        case .album:
            self.albumList[provider] = results as! [Album]?
            break
        case .playlist:
            self.playlistList[provider] = results as! [Playlist]?
            break
        default:
            break
        }
        
        //Refresh the reults view
        self.updateResultsTable()
    }
    
    func getResultHolder(section:MusicItemType) -> [ProviderType:[MusicItem]]? {
        switch section {
        case .track:
            return self.songsList
        case .artist:
            return self.artistList
        case .album:
            return self.albumList
        case .playlist:
            return self.playlistList
        default:
            return nil
        }
    }
    
    func updateResultsTable() {
        
        //Cut the full search results down for this fist screen
        guard let results = self.getResultHolder(section: self.selectedSection) else {return}
        let resultsArray = self.createShortFormArrayFromResults(results: results)

        if self.isResultsEmptyEmpty(results: resultsArray) {
            self.searchTable.reloadResults(results: nil)
        } else {
            self.searchTable.reloadResults(results: resultsArray)
        }
    }
    
    func isResultsEmptyEmpty(results:[[MusicItem]]) -> Bool {
        for arr in results {
            if arr.count > 0 {return false}
        }
        return true
    }
    
    //Need to order the results by a pre-determined priority of provider type
    func createArrayFromResults(results:[ProviderType:[MusicItem]]) -> [[MusicItem]] {
        
        var finalArray : [[MusicItem]] = []

        if let spotifyItems = results[.spotify] {if !spotifyItems.isEmpty {finalArray.append(spotifyItems)}}
        if let appleMusicItems = results[.appleMusic] {if !appleMusicItems.isEmpty {finalArray.append(appleMusicItems)}}    
        if let deezerItems = results[.deezer] {if !deezerItems.isEmpty {finalArray.append(deezerItems)}}
        if let soundcloudItems = results[.soundCloud] {if !soundcloudItems.isEmpty {finalArray.append(soundcloudItems)}}
        if let youtubeItems = results[.youtube] {if !youtubeItems.isEmpty {finalArray.append(youtubeItems)}}
        if let itunesItems = results[.iTunes] {if !itunesItems.isEmpty {finalArray.append(itunesItems)}}

        return finalArray
    }
    
    func createSubArray(array:[AnyObject], maxCount:Int) -> [AnyObject] {
        
        let realMax = min(maxCount, array.count)
        let slice = array[0..<realMax]
        return Array(slice)
    }
    
    func createShortFormArrayFromResults(results:[ProviderType:[MusicItem]]) -> [[MusicItem]] {
        
        let array = self.createArrayFromResults(results: results)
        var shortArray : [[MusicItem]] = []
        for arr in array {
            let shorty = self.createSubArray(array: arr, maxCount: self.searchSmallCount)
            shortArray.append(shorty as! [MusicItem])
        }
        return shortArray
    }
    
    
    //MARK: - Options
    func showOptions(musicItem:MusicItem?,options:[MusicOptionCellType]){
        
        self.navigationController?.view.endEditing(true)
        
        self.optionsVC = MusicPopupContainerVC.createFromStoryboard()
        self.optionsVC?.shouldHideStatusBar = true
        
        if self.optionsVC != nil {
            self.optionsVC?.setOptions(options)
            self.optionsVC?.musicItem = musicItem
            self.optionsVC?.showPopup(true)
            self.optionsVC?.originalVC = self
        }
            }

    //MARK: - Navigation
    func didSelectItem(item:MusicItem) {
        
        self.navigationController?.view.endEditing(true)

        //If song, play. Else go to more detail
        
        if let song = item as? Song {
            
            //Play song and add all to queue if needed
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
    
    func didSelectSongFromList(song:Song,list:[Song]) {
        self.playSongsWithinList(song: song, list: list)
    }
    
    func didSelectMoreResult(provider:ProviderType) {
        
        let section = self.getSelectedSection()
        let resultsHolder = self.getResultHolder(section: section)
        if let results = resultsHolder?[provider] {
            self.goToExtendedResults(results: results, provider: provider)
        } else {
            self.goToExtendedResults(results: nil, provider: provider)
        }
    }
    
    func goToExtendedResults(results:[MusicItem]?,provider:ProviderType) {
        self.navigationController?.view.endEditing(true)
        let extendedSearchVC = self.storyboard?.instantiateViewController(withIdentifier: "ExtendedSearchTableVC") as! ExtendedSearchTableVC
        extendedSearchVC.provider = provider
        extendedSearchVC.results = results
        self.navigationController?.pushViewController(extendedSearchVC, animated: true)
    }
    

}
