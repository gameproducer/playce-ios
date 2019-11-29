//
//  DiscoverHorizontalCell.swift
//  playce
//
//  Created by Tys Bradford on 10/1/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit

class DiscoverHorizontalCell: UITableViewCell {
    
    var items : [MusicItem] = []
    @IBOutlet weak var collectionView: UICollectionView!

    weak var discoverHomeVC : DiscoverHomeVC?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setItems(items:[MusicItem]) {
        self.items = items
        self.collectionView.reloadData()
        let indexpath = IndexPath(item: 0, section: 0)
        
        if !self.collectionView.contentOffset.equalTo(CGPoint.zero) {
            self.collectionView.scrollToItem(at: indexpath, at: UICollectionView.ScrollPosition.left, animated: false)
        }
    }
}


extension DiscoverHorizontalCell : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! DiscoveryCollectionCell
        
        //Set cell subviews
        let item = self.items[indexPath.row]
        
        cell.imageView.image = UIImage(named:"music_item_placeholder")
        cell.imageView.sd_setImage(with: item.getImageURL())
        cell.titleLabel.text = item.name
        
        if let song = item as? Song {
            let artistname = song.getArtistNameString()
            cell.subtitleLabel.text = artistname
        } else if let album = item as? Album {
            cell.subtitleLabel.text = album.getArtistNameString()
        } else if let playlist = item as? Playlist {
            cell.subtitleLabel.text = playlist.getNumberOfSongsString()
        } else if let artist = item as? Artist {
            cell.subtitleLabel.text = artist.getNumberOfSongsString()
        } else {
            cell.subtitleLabel.text = ""
        }
        
        
        return cell
    }
}

extension DiscoverHorizontalCell : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if self.discoverHomeVC != nil {
            
            let item = self.items[indexPath.row]
            if let songs = self.items as? [Song] {
                self.discoverHomeVC!.didSelectSongFromList(song: item as! Song, list: songs)
            } else {
                self.discoverHomeVC!.didSelectItem(item: item)
            }
        }
    }
}


extension DiscoverHorizontalCell : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = 146
        let itemHeight = 194
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
