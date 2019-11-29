//
//  MusicOptionCell.swift
//  playce
//
//  Created by Tys Bradford on 8/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//


enum MusicOptionCellType {
    case play
    case save
    case addPlaylist
    case addQueue
    case goArtist
    case goAlbum
    case share
    case edit
    case remove
}

class MusicOptionCell: UITableViewCell {

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var cellType : MusicOptionCellType?
    
    
    
    func setType(_ type:MusicOptionCellType) {
        
        cellType = type
        self.titleLabel.text = ""
        self.iconImage.image = nil
        
        switch type {
        case MusicOptionCellType.play:
            self.titleLabel.text = "Play"
            self.iconImage.image = UIImage(named: "options_ic_play")
            break
        case MusicOptionCellType.save:
            self.titleLabel.text = "Save"
            self.iconImage.image = UIImage(named: "options_ic_save")
            break
        case MusicOptionCellType.addPlaylist:
            self.titleLabel.text = "Add to Playlist"
            self.iconImage.image = UIImage(named: "options_ic_add_playlist")
            break
        case MusicOptionCellType.addQueue:
            self.titleLabel.text = "Add to Queue"
            self.iconImage.image = UIImage(named: "options_ic_add_queue")
            break
        case MusicOptionCellType.goArtist:
            self.titleLabel.text = "Go to Artist"
            self.iconImage.image = UIImage(named: "options_ic_go_artist")
            break
        case MusicOptionCellType.goAlbum:
            self.titleLabel.text = "Go to Album"
            self.iconImage.image = UIImage(named: "options_ic_go_album")
            break
        case MusicOptionCellType.share:
            self.titleLabel.text = "Share"
            self.iconImage.image = UIImage(named: "options_ic_share")
            break
        case MusicOptionCellType.edit:
            self.titleLabel.text = "Edit"
            self.iconImage.image = UIImage(named: "options_ic_edit")
            break
        case MusicOptionCellType.remove:
            self.titleLabel.text = "Remove"
            self.iconImage.image = UIImage(named: "options_ic_remove")
            break
        default:
            self.titleLabel.text = ""
            self.iconImage.image = nil
        }
    }
    
    

}
