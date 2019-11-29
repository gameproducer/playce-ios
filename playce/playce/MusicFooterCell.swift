//
//  MusicFooterCell.swift
//  playce
//
//  Created by Tys Bradford on 25/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class MusicFooterCell: UITableViewCell {

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
