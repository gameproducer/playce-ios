//
//  QueueTableVC.swift
//  playce
//
//  Created by Tys Bradford on 10/03/2017.
//  Copyright © 2017 gigster. All rights reserved.
//

import Foundation


class QueueTableVC : UITableViewController {
    
    var queue : [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    //View update
    func updateView() {
        if let songs = PlaybackHandler.sharedInstance.getFullQueue() {
            self.queue = songs
        } else {self.queue = []}
        
        self.tableView.reloadData()
    }
    
    
    //Table Delegate
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.queue.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "queueCell", for: indexPath) as! QueueCell
        let song = self.queue[indexPath.row]
        let currentQueueIndex = PlaybackHandler.sharedInstance.getCurrentIndexInQueue()
        
        cell.setSong(song: song, index: indexPath.row)
        cell.setSelected(selected: false)
        
        if currentQueueIndex != nil {
            if currentQueueIndex! == indexPath.row {cell.setSelected(selected: true)}
        }
        
        cell.isEditing = true
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        PlaybackHandler.sharedInstance.playSongFromQueue(index: indexPath.row)
    }
    
    
    
    //Editting cells
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete;
    }
    
    
    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == UITableViewCell.EditingStyle.delete {
            self.removeSongFromPlaylist(index: indexPath.row)
        }
    }
    
    func removeSongFromPlaylist(index:Int) {
        
        let song = self.queue[index]
        if let currentPlayIndex = PlaybackHandler.sharedInstance.getCurrentIndexInQueue() {
            
            if currentPlayIndex == index {
                return
                //PlaybackHandler.sharedInstance.skipPlaybackForward()
            }
        }
        
        self.tableView.beginUpdates()
        PlaybackHandler.sharedInstance.removeSongFromQueue(song: song)
        
        let indexPath = IndexPath(item: index, section: 0)
        self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.fade)
        self.updateView()
        self.tableView.endUpdates()
    }
    
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let remove = UITableViewRowAction(style: .normal, title: "REMOVE") { action, index in
            self.removeSongFromPlaylist(index: indexPath.row)
        }
     
        remove.backgroundColor = UIColor.white
        return [remove]
    }
 
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        PlaybackHandler.sharedInstance.moveSong(fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
    }
    
    
    
    
}


class QueueCell : UITableViewCell {
    
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var providerImage: UIImageView!

    override var showsReorderControl: Bool {
        get {
            return true // short-circuit to on
        }
        set { }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if editing == false {
            return // ignore any attempts to turn it off
        }
        
        super.setEditing(editing, animated: animated)
    }
    
    override func awakeFromNib() {
        
        //Set appearance of delete button
        let font = UIFont(name: ".SFUIText-Semibold", size: 10.0)
        let color = PLStyle.greenColor()
        let attributes = [NSAttributedString.Key.font:font,NSAttributedString.Key.foregroundColor:color]
        let attributedTitle = NSAttributedString(string: "REMOVE", attributes: attributes)
        UIButton.appearance(whenContainedInInstancesOf: [UIView.self,QueueCell.self]).setAttributedTitle(attributedTitle, for: .normal)
    }
    
    
    func setSong(song:Song,index:Int) {
        
        indexLabel.text = String(describing: index+1)
        titleLabel.text = song.name
        subtitleLabel.text = song.getArtistNameString()
        self.setProviderType(song.getProviderType())
    }
    
    func setProviderType(_ type: ProviderType) {
        
        switch type {
        case .spotify:
            self.providerImage.image = UIImage(named:"music_provider_small_spotify")
            break
        case .iTunes:
            self.providerImage.image = UIImage(named:"music_provider_small_itunes")
            break
        case .soundCloud:
            self.providerImage.image = UIImage(named:"music_provider_small_soundcloud")
            break
        case .youtube:
            self.providerImage.image = UIImage(named:"music_provider_small_youtube")
            break
        case .deezer:
            self.providerImage.image = UIImage(named:"music_provider_small_deezer")
            break
        case .appleMusic:
            self.providerImage.image = UIImage(named:"music_provider_small_apple")
        default:
            self.providerImage.image = nil
        }
    }
    
    
    func setSelected(selected:Bool) {
        
        if selected {
            self.indexLabel.textColor = PLStyle.greenColor()
            self.titleLabel.textColor = PLStyle.greenColor()
        } else {
            self.indexLabel.textColor = PLStyle.colorWithHex("7F7F7F")
            self.titleLabel.textColor = PLStyle.colorWithHex("212121")
        }
        
    }
}
