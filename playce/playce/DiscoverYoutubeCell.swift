//
//  DiscoverYoutubeCell.swift
//  playce
//
//  Created by Tys Bradford on 9/1/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit


internal class DiscoverYoutubeCell : UITableViewCell {
    
    
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var shadowImage: UIImageView!
    
    @IBOutlet weak var bottomTitleLabel: UILabel!
    @IBOutlet weak var bottomSubtitleLabel: UILabel!
    
    @IBOutlet weak var bottomImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        shadowImage.layer.shadowColor = UIColor.black.cgColor
        shadowImage.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        shadowImage.layer.shadowOpacity = 0.2
        shadowImage.layer.shadowRadius = 3.0
        
        bottomImage.layer.masksToBounds = true
        bottomImage.layer.cornerRadius = 37.0 * 0.5
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    func setItem(item:MusicItem) {
        
        mainImage.image = nil
        bottomImage.image = nil

        mainImage.image = UIImage(named:"music_item_placeholder")
        mainImage.sd_setImage(with: item.getImageURL())
        
        bottomTitleLabel.text = item.name
        
        if let song = item as? Song {
            bottomSubtitleLabel.text = song.getArtistNameString()
            if let artists = song.artistList {
                if artists.count > 0 {
                    let artist = artists[0]
                    bottomImage.image = UIImage(named:"music_item_placeholder")
                    bottomImage.sd_setImage(with: artist.getImageURL())
                }
            }
        } else {
            bottomSubtitleLabel.text = ""
        }
    }
    
    

    
    
}
