//
//  MusicOptionHeaderCell.swift
//  playce
//
//  Created by Tys Bradford on 8/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

class MusicOptionHeaderCell: UITableViewCell {

    
    @IBOutlet weak var headerImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var headerImageWidthConstraint: NSLayoutConstraint!
    
    
    func setItem(item:MusicItem) {
        
        self.headerImage.image = nil
        if let imageURL = item.getImageURL() {self.headerImage.sd_setImage(with: imageURL)}
        else if let localImage = item.getLocalImage() {
            self.headerImage.image = localImage
        } else {
            self.headerImage.image = UIImage(named:"music_item_placeholder")
        }
        
        self.headerImageWidthConstraint.constant = 40.0
        self.headerImage.layer.cornerRadius = 0.0

        if let song = item as? Song {
            
            self.titleLabel.text = song.name
            self.subtitleLabel.text = song.getArtistNameString()
            if song.getProviderType() == .youtube {self.setAsVideo()}

        } else if let artist = item as? Artist {
            self.titleLabel.text = artist.name
            self.subtitleLabel.text = ""
            
            self.headerImage.layer.cornerRadius = 20.0
            self.headerImage.layer.masksToBounds = true
            
        } else if let album = item as? Album {
            self.titleLabel.text = album.name
            self.subtitleLabel.text = album.getArtistNameString()
            
        } else if let playlist = item as? Playlist {
            self.titleLabel.text = playlist.name
            self.subtitleLabel.text = playlist.getNumberOfSongsString()
        }
    }
    
    func setAsVideo() {
        
        //Make the image header wider...
        self.headerImageWidthConstraint.constant = 78.0
    }
    
}
