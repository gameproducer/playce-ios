//
//  MusicTableVC.swift
//  playce
//
//  Created by Tys Bradford on 29/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

class MusicTableVC: UITableViewController {

    static let sectionIndexes : [String] = ["#","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
    var sectionIndexVisible : Bool = false
    var optionsVC : MusicPopupContainerVC?
    var customLoadingIndicator : CustomLoadIndicator!
    let kMinItemCountForSectionShow : Int = 6

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Table
        self.tableView.tableFooterView = UIView()
        
        //Section index
        self.tableView.sectionIndexColor = PLStyle.greenColor()
        
        //Options
        self.optionsVC = MusicPopupContainerVC.createFromStoryboard()
        self.optionsVC?.shouldHideStatusBar = true
        
        //Loading
        var parentView = self.view
        if (self.navigationController != nil) {parentView = self.navigationController!.view!}
        self.customLoadingIndicator = CustomLoadIndicator(parentView: parentView!)
        
        //PlaybackBar UI handling
        self.adjustForPlaybackBar()
        
        //iOS11 Fix
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
    }
    
    deinit {
        self.removeListenersForPlaybackHideShow()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        //Search
        if let navController = self.navigationController as? PLNavController {
            
            (self.navigationController as? PLNavController)?.showSearchButton(true)
            var didComeFromSearch = false
            
            if let vc = navController.viewControllers.first {
                if vc is DiscoverHomeVC {didComeFromSearch = true}
            }
            
            if !didComeFromSearch {navController.showSearchButton(true)}
        }
    }
    
    // MARK: Section Index
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if sectionIndexVisible {return MusicTableVC.sectionIndexes}
        else {return nil}
    }
    
    // MARK: - Options
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
            self.optionsVC?.originalVC = self
            self.optionsVC?.showPopup(true)
        }
    }
    
    func showOptionsWithPlaylist(musicItem:MusicItem?,options:[MusicOptionCellType],playlist:Playlist?){
        
        self.showOptions(musicItem: musicItem, options: options)
        self.optionsVC?.parentItem = playlist
    }
    
    // MARK: - Convenience
    static func sortItemsIntoAlphaSections(items:[MusicItem]?) -> [[MusicItem]] {
        
        var containerArray : [[MusicItem]] = []
        
        guard let items = items else {return []}
        let sortedArray = items.sorted(by: {$0.name! < $1.name!})
        
        for _ in MusicTableVC.sectionIndexes {
            containerArray.append([])
        }
        
        let letters = CharacterSet.letters
        for musicItem in sortedArray {
            
            if let name = musicItem.name {
                if name.count == 0 {continue}
                let firstChar = name[name.startIndex]
                let firstCharUpper = String(firstChar).uppercased()
                let foundRange = firstCharUpper.rangeOfCharacter(from: letters)
                
                //Check if alpha or non-alpha
                if foundRange != nil {
                    if let index = MusicTableVC.sectionIndexes.index(of: firstCharUpper) {
                        containerArray[index].append(musicItem)
                    }
                } else {
                    containerArray[0].append(musicItem)
                }
            }
        }
        
        return containerArray
    }
    
    func getIndexPathFromCellSubview(view:UIView) -> IndexPath? {
        let viewPosition = view.convert(CGPoint.zero, to: self.tableView)
        return self.tableView.indexPathForRow(at: viewPosition)
        
    }
}
