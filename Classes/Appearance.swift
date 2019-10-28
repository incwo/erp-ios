//
//  Appearance.swift
//  facile
//
//  Created by Renaud Pradenc on 28/10/2019.
//

import Foundation
import UIKit

class Appearance: NSObject {
    
    @objc static func setup() {
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: darkGrey()]
        UINavigationBar.appearance().tintColor = blue()
        
        UITabBar.appearance().tintColor = blue()
    }
    
    // MARK: Colors
    
    @objc static func lightGrey() -> UIColor {
        UIColor(white: 222.0/255.0, alpha: 1.0)
    }
    
    @objc static func darkGrey() -> UIColor {
        UIColor(white: 65.0/255.0, alpha: 1.0)
    }
    
    @objc static func blue() -> UIColor {
        UIColor(red: 20.0/255.0, green: 93.0/255.0, blue: 151.0/255.0, alpha: 1.0)
    }
    
    @objc static func red() -> UIColor {
        UIColor(red: 218.0/255.0, green: 79.0/255.0, blue: 73.0/255.0, alpha: 1.0)
    }
}
