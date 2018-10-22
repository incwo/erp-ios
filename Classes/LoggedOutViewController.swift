//
//  LoggedOutViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import UIKit

class LoggedOutViewController: UIViewController {
    public var onLogInButton: ( ()->() )?
    
    @IBAction func logIn(_ sender: Any) {
        if let onLogInButton = onLogInButton {
            onLogInButton()
        }
    }
}
