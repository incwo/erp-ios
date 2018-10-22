//
//  SidePanelViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import UIKit

class SidePanelViewController: UIViewController {
    public var onCloseButton: ( ()->() )?
    public private (set) var businessFilesTableViewController: BusinessFilesTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "EmbedBusinessFiles":
            businessFilesTableViewController = segue.destination as? BusinessFilesTableViewController
        default:
            break
        }
    }
    
    @IBAction func close(_ sender: Any) {
        onCloseButton?()
    }
}
