//
//  BusinessFilesTableViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import UIKit

class BusinessFilesTableViewController: UITableViewController {
    public var businessFiles: [FCLFormsBusinessFile]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    /// Called when a Business File is selected in the table
    public var onSelection: ((FCLFormsBusinessFile) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let businessFiles = businessFiles {
            return businessFiles.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let businessFiles = businessFiles else {
            fatalError("This method is not expected to be called if there are no business files.")
        }
        let businessFile = businessFiles[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "businessFileCell", for: indexPath)
        cell.textLabel?.text = businessFile.name

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let businessFiles = businessFiles else {
            fatalError("This method is not expected to be called if there are no business files.")
        }
        
        if let onSelection = onSelection {
            onSelection(businessFiles[indexPath.row])
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
