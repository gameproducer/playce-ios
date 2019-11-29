//
//  PLActivityIndicator.swift
//  playce
//
//  Created by Tys Bradford on 1/08/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import SVProgressHUD

class PLActivityIndicator: NSObject {

    
    static let sharedIndicator: PLActivityIndicator = PLActivityIndicator()
    
    override init() {
        
        super.init()
        
        //Customise the look of the HUD display
        
    }
    
    
    func startShowing() {
        
        SVProgressHUD.show()

    }
    
    func stopShowing() {
        
        SVProgressHUD.dismiss()

    }
}
