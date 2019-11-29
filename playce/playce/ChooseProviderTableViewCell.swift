//
//  ChooseProviderTableViewCell.swift
//  playce
//
//  Created by Benjamin Hendricks on 5/25/16.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

enum Provider: String {
    case Spotify = "Spotify"
    case Youtube = "YouTube"
    case iTunesLibrary = "iTunes"
    case SoundCloud = "Soundcloud"
    case Deezer = "Deezer"
    case Apple = "Apple Music"
}

class ChooseProviderTableViewCell: UITableViewCell {

    static let reuseId: String = "providerCell"
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var providerImageView: UIImageView!
    @IBOutlet weak var providerTitleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var detailButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.layer.cornerRadius = 17
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 1.0
        containerView.layer.borderColor = cellLightGrayColor().cgColor
    }
    
    func setup(_ provider: Provider, isConnected: Bool = false) {
        
        providerTitleLabel.text = provider.rawValue
        var imgName = ""
        
        switch provider {
        case .Spotify:
            imgName = "provider_logo_spotify"
        case .Youtube:
            imgName = "provider_logo_youtube"
        case .iTunesLibrary:
            imgName = "provider_logo_itunes"
        case .SoundCloud:
            imgName = "provider_logo_soundcloud"
        case .Deezer:
            imgName = "provider_logo_deezer"
        case .Apple:
            imgName = "provider_logo_apple"
        }
        
        //If selected then modify img name
        if isConnected {
            imgName += "_sel"
        }
        
        providerImageView.image = UIImage(named: imgName)
        
        if isConnected {
            
            containerView.backgroundColor = UIColor(red:0.13, green:0.13, blue:0.13, alpha:1.0)
            containerView.layer.borderWidth = 0.0
            providerTitleLabel.textColor = UIColor.white
            statusLabel.text = "Connected"
            statusLabel.textColor = UIColor.white
            detailButton.setImage(UIImage(named: "item_select_cancel"), for: .normal)
            
        } else {
            
            containerView.backgroundColor = UIColor.white
            containerView.layer.borderWidth = 1.0
            providerTitleLabel.textColor = cellLightGrayColor()
            statusLabel.text = "Tap to connect"
            statusLabel.textColor = cellLightGrayColor()
            detailButton.setImage(UIImage(named: "item_select_chevron"), for: .normal)
        }
    }
    
    fileprivate func cellLightGrayColor() -> UIColor {
        
        return UIColor(red:0.89, green:0.89, blue:0.89, alpha:1.0)
    }

}
