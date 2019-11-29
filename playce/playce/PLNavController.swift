//
//  PLNavController.swift
//  playce
//
//  Created by Tys Bradford on 14/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit
import SlideMenuControllerSwift


class PLNavController: UINavigationController, UISearchBarDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate {

    static let kPLSearchBarDidCancelNotification = "kPLSearchBarDidCancelNotification"
    
    var backButton : UIButton!
    var menuButton : UIButton!
    var searchButton : UIButton!
    var searchBar : UISearchBar!
    var searchCancelButton : UIButton!
    var searchDelegate : AnyObject?
    
    convenience init() {
        
        self.init(nibName: nil, bundle: nil)
        setupView()
        self.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func setupView() {
        
        // Do any additional setup after loading the view.
        initNavbar()
        initSearchItems()
        
        // Set navbar appearances
        var titleFont : UIFont?
        
        if #available(iOS 8.2, *) {
            titleFont = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.semibold)
        } else {
            // Fallback on earlier versions
            titleFont = UIFont(name: "SFUIText-Semibold", size: 17.0)!
        }
        
        if titleFont == nil {
            titleFont = UIFont.systemFont(ofSize: 17.0)
        }
        
        let titleAttributes : [NSAttributedString.Key : AnyObject] = [.foregroundColor : UIColor.black, .font : titleFont!]
        self.navigationBar.titleTextAttributes = titleAttributes
        
        self.navigationBar.isTranslucent = false
        self.navigationBar.barTintColor = UIColor.init(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
        self.navigationBar.shadowColor = UIColor.black
        // WARNING: No properties
        self.navigationBar.layer.shadowOpacity = 1.0
        self.navigationBar.layer.shadowRadius = 4.0
//        self.navigationBar.shadowOpacity = 1.0
//        self.navigationBar.shadowRadius = 4.0
        
        self.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationBar.shadowImage = UIImage()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Swipe back handler
        if let gr = self.interactivePopGestureRecognizer {
            gr.delegate = self
            gr.isEnabled = true
        }
    }
    
    
    // MARK: - Navbar
    fileprivate func initNavbar() {
        
        backButton = UIButton(frame: CGRect(x: 0.0, y: -2.0, width: 50.0, height: 50.0))
        menuButton = UIButton(frame: CGRect(x: 0.0, y: -2.0, width: 50.0, height: 50.0))

        backButton.contentMode = .center
        menuButton.contentMode = .center
        
        backButton.setImage(UIImage(named: "back_arrow"), for: UIControl.State())
        menuButton.setImage(UIImage(named: "nav_menu_button"), for: UIControl.State())

        backButton.isHidden = true
        menuButton.isHidden = false
        
        backButton.addTarget(self, action: #selector(PLNavController.backButtonPressed), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(PLNavController.menuButtonPressed), for: .touchUpInside)
        
        self.navigationBar.addSubview(backButton)
        self.navigationBar.addSubview(menuButton)
        
        self.navigationBar.tintColor = PLStyle.greenColor()
    }
    
    func setBackButtonVisible(_ visible: Bool) {
        backButton.isHidden = !visible
        if visible {
            setMenuButtonVisible(false)
        }
    }
    
    func setMenuButtonVisible(_ visible: Bool) {
        menuButton.isHidden = !visible
        if (visible){
            setBackButtonVisible(false)
        }
    }
    
    @objc func backButtonPressed() {
        _ = self.popViewController(animated: true)
    }
    
    @objc func menuButtonPressed() {
        if let slideVC = slideMenuController() {
            slideVC.openLeft()
        }
    }
    
    // MARK: Swipe Gesture Handler
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(self.viewControllers.count > 1){
            return true
        } else {
            return false
        }
    }
    
    
    // MARK: - Search
    fileprivate func initSearchItems() {
        
        let buttonWidth : CGFloat = 70.0
        let rightMargin : CGFloat = 0.0
        let navbarWidth = UIScreen.main.bounds.width
        let buttonX = navbarWidth-rightMargin-buttonWidth
        
        //Search button
        searchButton = UIButton(frame: CGRect(x: buttonX, y: -2.0, width: buttonWidth, height: 50.0))
        searchButton.contentMode = .center
        searchButton.setImage(UIImage(named: "nav_search_button"), for: UIControl.State())
        searchButton.setImage(UIImage(), for: UIControl.State.selected)
        searchButton.isHidden = true
        searchButton.addTarget(self, action: #selector(PLNavController.searchButtonPressed), for: .touchUpInside)
        searchButton.setTitle("", for: UIControl.State())
        searchButton.setTitle("Cancel", for: UIControl.State.selected)
        searchButton.setTitleColor(PLStyle.greenColor(), for: UIControl.State.selected)
        self.navigationBar.addSubview(searchButton)
        
        //Search bar
        let posX : CGFloat = 50.0
        let posY : CGFloat = 10.0
        let barHeight : CGFloat = 28.0
        let barWidth : CGFloat = navbarWidth - posX - searchButton.frame.size.width
        searchBar = UISearchBar(frame: CGRect(x: posX, y: posY, width: barWidth, height: barHeight))
        searchBar.returnKeyType = UIReturnKeyType.search
        searchBar.barTintColor = PLStyle.colorWithHex("E4E4E4")
        searchBar.delegate = self
        searchBar.isHidden = true
        
        self.navigationBar.addSubview(searchBar)
    }
    
    func showSearchButton(_ visible:Bool) {
        searchButton.isHidden = !visible
    }
    
    func isSearchBarShowing() -> Bool {
        return !searchBar.isHidden
    }
    
    @objc func searchButtonPressed() {
        
        let isSelected = self.searchButton.isSelected
        if isSelected {
            searchCancelButtonPressed()
        } else {
            showSearchBar(true)
        }
        
        self.searchButton.isSelected = !isSelected
    }
    
    func searchCancelButtonPressed() {
        //Hide keyboard and search bar
        hideSearchBar(true)
        searchBar.resignFirstResponder()
        searchBar.text = ""
        
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: PLNavController.kPLSearchBarDidCancelNotification)))
    }
    
    func showSearchBar(_ animated: Bool) {
        
        if animated {
            searchBar.alpha = 0.0
            searchBar.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.searchBar.alpha = 1.0
            })
        } else {
            searchBar.isHidden = false
        }
        
        self.navigationBar.bringSubviewToFront(searchBar)
        searchButton.isSelected = true
        hideTitleLabel(animated)
        
        searchBar.becomeFirstResponder()
    }
    
    func resignSearchBarResponder() {
        searchBar.resignFirstResponder()
    }
    
    func hideSearchBar(_ animated: Bool) {
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: { 
                self.searchBar.alpha = 0.0
                }, completion: { (completed) in
                    self.searchBar.isHidden = true
            })
        } else {
            searchBar.isHidden = true
        }
        
        searchButton.isSelected = false
        showTitleLabel(animated)
        self.searchBar.resignFirstResponder()
    }
    
    func showTitleLabel(_ animated:Bool) {
        
        if let vc = self.getCurrentVC(){
            vc.navigationItem.titleView?.isHidden = false
        }
        self.getCurrentVC()?.navigationItem.titleLabel.isHidden = false
    }
    
    func hideTitleLabel(_ animated:Bool) {
        self.getCurrentVC()?.navigationItem.titleLabel.isHidden = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        //If currently on Discovery screen -> search for selected section.
        //Else, navigate to Discovery and search for Tracks
        let searchScreen = self.getCurrentVC() as? DiscoverHomeVC
        if searchScreen == nil {
            performLocalSearch()
        } else {
            searchScreen?.performSearch(searchString: searchBar.text)
        }
    }
    
    func performLocalSearch() {
        
        //Filter out local items based on search string
        guard let searchString = searchBar.text else {return}
        guard let mainVC = self.viewControllers.last else {return}
        let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
        let searchVC = storyboard.instantiateViewController(withIdentifier: "ExtendedSearchTableVC") as! ExtendedSearchTableVC
        
        var itemType : MusicItemType = .none
        var originalItems : [MusicItem] = []
        if let songVC = mainVC as? SongsViewController {
            itemType = .track
            originalItems = songVC.mySongs
        }
        else if let albumVC = mainVC as? AlbumTableVC {
            itemType = .album
            originalItems = albumVC.myAlbums
        }
        else if let artistVC = mainVC as? ArtistTableVC {
            itemType = .artist
            originalItems = artistVC.myArtists
        }
        else if let playlistVC = mainVC as? PlaylistTableVC {
            itemType = .playlist
            originalItems = playlistVC.myPlaylists
        }
        else if let detailVC = mainVC as? MusicDetailTableVC {
            itemType = .track
            originalItems = detailVC.songs ?? []
        }
        
        //Push to new search results screen
        let filteredItems = LibraryHandler.filterItems(items: originalItems, searchString:searchString)
        searchVC.customTitle = searchString
        searchVC.results = filteredItems
        self.pushViewController(searchVC, animated: true)
    }
    
    // MARK: - Helpers
    func getCurrentVC()->UIViewController? {
        let vc = self.viewControllers.last
        return vc
    }
    
    // MARK: - Overrides
    override func popViewController(animated: Bool) -> UIViewController? {
        hideSearchBar(false)
        prepareBarButtonPop(self.viewControllers)
        return super.popViewController(animated: animated)
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        hideSearchBar(false)
        prepareBarButtonPop(self.viewControllers)
        return super.popToViewController(viewController, animated: animated)
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        hideSearchBar(false)
        setMenuButtonVisible(true)
        return super.popToRootViewController(animated: animated)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        
        hideSearchBar(false)
        setBackButtonVisible(true)
        viewController.navigationItem.setHidesBackButton(true, animated: false)
        super.pushViewController(viewController, animated: animated)
    }
    
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        hideSearchBar(false)
        prepareBarButton(viewControllers)
        super.setViewControllers(viewControllers, animated: animated)
    }
    
    func prepareBarButton(_ futureViewControllers : [UIViewController]) {
    
        if (viewControllers.count > 1){
            setBackButtonVisible(true)
        } else {
            setMenuButtonVisible(true)
        }
    }
    
    func prepareBarButtonPop(_ currentViewControllers : [UIViewController]) {
        
        if (viewControllers.count > 2){
            setBackButtonVisible(true)
        } else {
            setMenuButtonVisible(true)
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        let stackCount = navigationController.viewControllers.count
        if stackCount > 1 {
            SlideMenuOptions.panFromBezel = false
        } else {
            SlideMenuOptions.panFromBezel = true
        }
    }
}
