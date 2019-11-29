//
//  MusicItemCell.swift
//  playce
//
//  Created by Tys Bradford on 21/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class MusicItemCell: UITableViewCell {

    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var providerThumbnail: UIImageView!
    @IBOutlet weak var moreButton: UIButton!
    weak var musicItem : MusicItem? {
        didSet {
            configureView()
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setProviderType(_ type: ProviderType) {
                
        switch type {
        case .spotify:
            providerThumbnail.image = UIImage(named:"music_provider_small_spotify")
            break
        case .iTunes:
            providerThumbnail.image = UIImage(named:"music_provider_small_itunes")
            break
        case .soundCloud:
            providerThumbnail.image = UIImage(named:"music_provider_small_soundcloud")
            break
        case .youtube:
            providerThumbnail.image = UIImage(named:"music_provider_small_youtube")
            break
        case .deezer:
            providerThumbnail.image = UIImage(named:"music_provider_small_deezer")
            break
        case .appleMusic:
            providerThumbnail.image = UIImage(named:"music_provider_small_apple")
            break
        default:
            if self.musicItem is Playlist {
                providerThumbnail.image = UIImage(named:"music_provider_small_playce")
            } else {
                providerThumbnail.image = nil
            }
        }
    }
    
    func setThumbnailImage(_ musicItem : MusicItem) {
        
        if let imgURL = musicItem.getImageURL() {
            self.thumbnail.sd_setImage(with: imgURL as URL?)
        } else if musicItem.isLocal {self.thumbnail.image = musicItem.getLocalImage()}
        else {
            self.thumbnail.image = UIImage(named:"music_item_placeholder")
        }
    }
    
    func configureView() {
        
        guard let item = self.musicItem else {return}
        self.makeThumbnailNormal()
        self.subtitleLabel.text = ""
        
        if item.isKind(of: Album.self) {
            self.subtitleLabel.text = (item as? Album)?.getArtistNameString()
        } else if item.isKind(of: Artist.self) {
            self.subtitleLabel.text = (item as? Artist)?.getNumberOfSongsString()
            self.makeThumbnailCircular()
        } else if item.isKind(of: Playlist.self) {
            self.subtitleLabel.text = (item as? Playlist)?.getNumberOfSongsString()
        } else if item.isKind(of: Song.self) {
            self.subtitleLabel.text = (item as? Song)?.getArtistNameString()
        }
        
        self.titleLabel.text = item.name
        self.thumbnail.image = nil
        self.setThumbnailImage(item)
        self.setProviderType(item.getProviderType())
        self.selectionStyle = UITableViewCell.SelectionStyle.default

    }
    
    func makeThumbnailCircular() {
        thumbnail.layer.cornerRadius = 25.0
        thumbnail.layer.masksToBounds = true
    }
    
    func makeThumbnailNormal() {
        thumbnail.layer.cornerRadius = 0.0
    }

}
