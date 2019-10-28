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
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: navigationBarTitleColor()]
        UINavigationBar.appearance().tintColor = accentColor()
        
        UITabBar.appearance().tintColor = accentColor()
    }
    
    // MARK: Colors
    
    private static func navigationBarTitleColor() -> UIColor {
        if #available(iOS 11, *) {
            return UIColor(named: "navigationBar.title")!
        } else {
            return UIColor(white: 65.0/255.0, alpha: 1.0)
        }
    }
    
    @objc static func accentColor() -> UIColor {
        if #available(iOS 11, *) {
            return UIColor(named: "accent")!
        } else {
            return UIColor(red: 20.0/255.0, green: 93.0/255.0, blue: 151.0/255.0, alpha: 1.0)
        }
    }
    
    @objc static func destructiveActionColor() -> UIColor {
        if #available(iOS 11, *) {
            return UIColor(named: "destructiveAction")!
        } else {
            return UIColor(red: 218.0/255.0, green: 79.0/255.0, blue: 73.0/255.0, alpha: 1.0)
        }
    }
    
    @objc static func tabBarControllerBackgroundColor() -> UIColor {
        if #available(iOS 11, *) {
            return UIColor(named: "tabBarController.background")!
        } else {
            return UIColor.white
        }
    }
}
