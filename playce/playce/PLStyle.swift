//
//  PLStyle.swift
//  playce
//
//  Created by Tys Bradford on 28/07/2016.
//  Copyright © 2016 gigster. All rights reserved.
//

import UIKit

class PLStyle: NSObject {

    
    // MARK: - Helpers
    static func colorWithRGB(_ red:Int, green:Int, blue:Int, alpha:Float) -> UIColor {
        
        return UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: CGFloat(alpha))
    }
    
    static func colorWithHex(_ hex: String) -> UIColor {
        return hexStringToUIColor(hex)
    }
    
    static func hexStringToUIColor (_ hex:String) -> UIColor {
        
        var cString:String = hex.trimmingCharacters(in: (NSCharacterSet.whitespacesAndNewlines as NSCharacterSet) as CharacterSet).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString = cString.substring(from: cString.index(cString.startIndex, offsetBy: 1))
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    
    // MARK: - Colors
    static func greenColor()->UIColor {
        return colorWithRGB(61, green: 183, blue: 170, alpha: 1.0)
    }
    
    
    
}


