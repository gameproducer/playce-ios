//
//  DiscoverSoundcloudCell.swift
//  playce
//
//  Created by Tys Bradford on 9/1/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit

class DiscoverSoundcloudCell: UITableViewCell {
    
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var shadowView: UIImageView!
    @IBOutlet weak var bottomTitleLabel: UILabel!
    @IBOutlet weak var bottomSubtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 3.0
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setItem(item:MusicItem) {
        
        mainImage.image = UIImage(named:"music_item_placeholder")
        mainImage.sd_setImage(with: item.getImageURL())
        
        bottomTitleLabel.text = item.name
        
        if let song = item as? Song {
            bottomSubtitleLabel.text = song.getArtistNameString()
        } else {
            bottomSubtitleLabel.text = ""
        }
    }

}
