//
//  MusicPopupTableVC.swift
//  playce
//
//  Created by Tys Bradford on 5/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//


class MusicPopupTableVC: UITableViewController {

    
    var options : [MusicOptionCellType]?
    var containerVC : MusicPopupContainerVC?
 
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        //Table
        self.tableView.tableFooterView = UIView()
        self.tableView.showsVerticalScrollIndicator = false
        self.view.clipsToBounds = false
        self.tableView.clipsToBounds = false
        
        //iOS11
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func updateView() {
        self.tableView.reloadData()
    }
    
    
    //MARK: - Table Source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {return 1}
        else if self.options == nil {return 0}
        else {return self.options!.count}
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section == 0 {return 62.0}
        else {return 51.0}
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath as NSIndexPath).section == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "optionsHeaderCell", for: indexPath) as! MusicOptionHeaderCell
            cell.backgroundColor = UIColor.clear
            if let item = self.containerVC?.musicItem {
                cell.setItem(item: item)
            }
            return cell
        }
        else {
            
            if let cell = tableView.dequeueReusableCell(withIdentifier: "optionsCell", for: indexPath) as? MusicOptionCell {
                
                cell.backgroundColor = UIColor.clear
                cell.setType(getOptionType(indexPath: indexPath))
                return cell
            } else {
                return tableView.dequeueReusableCell(withIdentifier: "optionsCell", for: indexPath);
            }
            
        }
    }
    
    func getOptionType(indexPath:IndexPath) -> MusicOptionCellType {
        let index = indexPath.row
        if options != nil {
            if index < self.options!.count {
                return self.options![index]
            }
        }
        return .share
    }
    
    
    //MARK: - Helpers
    func calculateTableHeight() -> CGFloat{
        
        var totalHeight : CGFloat = 0.0
        totalHeight += self.tableView(self.tableView, heightForRowAt: IndexPath(row: 0, section: 0))
        
        guard let itemCount = self.options?.count else {return 0.0}
        
        for i in 0...(itemCount-1){
            let cellHeight = self.tableView(self.tableView, heightForRowAt: IndexPath(row: i, section: 1))
            totalHeight += cellHeight
        }
        return totalHeight
    }
    
    //MARK: - Actions
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        if let containerVC = self.containerVC {
            let optionType = getOptionType(indexPath: indexPath)
            containerVC.selectionMade(cellType: optionType)
        }
    }
    
}
