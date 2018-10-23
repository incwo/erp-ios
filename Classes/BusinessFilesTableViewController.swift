//
//  BusinessFilesTableViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import UIKit

class BusinessFilesTableViewController: UITableViewController {
    struct ViewModel {
        let businessFiles: [FCLFormsBusinessFile]
        let selectedBusinessFile: FCLFormsBusinessFile
    }
    
    public var viewModel: ViewModel? {
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
        if let viewModel = viewModel {
            return viewModel.businessFiles.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = viewModel else {
            fatalError("The method is not supposed to be called if there is no viewModel.")
        }
        let businessFile = viewModel.businessFiles[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "businessFileCell", for: indexPath)
        cell.textLabel?.text = businessFile.name
        cell.accessoryType = (businessFile == viewModel.selectedBusinessFile) ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel = viewModel else {
            fatalError("The method is not supposed to be called if there is no viewModel.")
        }
        
        if let onSelection = onSelection {
            onSelection(viewModel.businessFiles[indexPath.row])
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
