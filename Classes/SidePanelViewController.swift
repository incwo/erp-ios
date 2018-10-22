//
//  SidePanelViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import UIKit

class SidePanelViewController: UIViewController {
    public var onCloseButton: ( ()->() )?
    public var onBusinessFileSelection: ( (FCLFormsBusinessFile) -> () )? {
        didSet {
            businessFilesTableViewController?.onSelection = onBusinessFileSelection
        }
    }
    public var businessFiles: [FCLFormsBusinessFile]? {
        didSet {
            businessFilesTableViewController?.businessFiles = businessFiles
        }
    }
    private var businessFilesTableViewController: BusinessFilesTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "EmbedBusinessFiles":
            self.businessFilesTableViewController = segue.destination as? BusinessFilesTableViewController
            businessFilesTableViewController!.businessFiles = businessFiles
            businessFilesTableViewController!.onSelection = onBusinessFileSelection
        default:
            break
        }
    }
    
    @IBAction func close(_ sender: Any) {
        onCloseButton?()
    }
}
