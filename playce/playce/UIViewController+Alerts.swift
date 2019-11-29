//
//  UIViewController+Alerts.swift
//  playce
//
//  Created by Tys Bradford on 16/5/18.
//  Copyright © 2018 gigster. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func showAlert(title:String,message:String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionOK = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        ac.addAction(actionOK)
        self.present(ac, animated: true, completion: nil)
    }
}
