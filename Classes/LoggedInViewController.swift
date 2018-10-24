//
//  LoggedInViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import UIKit

class LoggedInViewController: UIViewController {
    public var username: String? {
        didSet {
            if usernameLabel != nil {
                usernameLabel.text = username
            }
        }
    }
    public var onLogOutButton: ( ()->() )?
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        usernameLabel.text = username
    }
    
    @IBAction func logOut(_ sender: Any) {
        if let onLogOutButton = onLogOutButton {
            onLogOutButton()
        }
    }
}
