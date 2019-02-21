//
//  UIColorExten.swift
//  Ladder-iOS
//
//  Created by TsanFeng Lam on 2019/2/20.
//  Copyright © 2019 Aofei Sheng. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    convenience init(hex: String) {
        self.init(hex: hex, alpha: 1)
    }
    
    convenience init(hex: String, alpha: CGFloat) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff,
            alpha: alpha
        )
    }
    
    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    static func random() -> UIColor {
        return UIColor(red: CGFloat(arc4random()%255 / 255), green: CGFloat(arc4random()%255 / 255), blue: CGFloat(arc4random()%255 / 255), alpha: 1.0)
    }
    
}
