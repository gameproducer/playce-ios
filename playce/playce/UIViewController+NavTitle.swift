//
//  UIViewController+NavTitle.swift
//  playce
//
//  Created by Tys Bradford on 12/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func setTruncatedTitle(_ title:String?) {
        
        guard let title = title else {return}
       
        let maxStringLength = 25
        var newTitle = title
        
        if title.count > maxStringLength {
            newTitle = title.substring(to: title.index(title.startIndex, offsetBy: maxStringLength))
            newTitle = newTitle + "..."
        }
        
        self.title = newTitle

        
    }
    
    
}
