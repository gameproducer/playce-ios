//
//  DiscoveryCollectionCell.swift
//  playce
//
//  Created by Tys Bradford on 12/1/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import UIKit

class DiscoveryCollectionCell: UICollectionViewCell {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0.0, height: 4.0)
        imageView.layer.shadowOpacity = 0.2
        imageView.layer.shadowRadius = 3.0
    }
}
