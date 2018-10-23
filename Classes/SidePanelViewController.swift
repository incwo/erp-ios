//
//  SidePanelViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import UIKit

class SidePanelViewController: UIViewController {
    struct ViewModel {
        let businessFiles: [FCLFormsBusinessFile]
        let selectedBusinessFile: FCLFormsBusinessFile
    }
    
    public var viewModel: ViewModel? {
        didSet {
            setBusinessFilesTableViewControllerViewModel()
        }
    }
    public var onCloseButton: ( ()->() )?
    public var onBusinessFileSelection: ( (FCLFormsBusinessFile) -> () )? {
        didSet {
            businessFilesTableViewController?.onSelection = onBusinessFileSelection
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
            setBusinessFilesTableViewControllerViewModel()
            businessFilesTableViewController!.onSelection = onBusinessFileSelection
        default:
            break
        }
    }
    
    private func setBusinessFilesTableViewControllerViewModel() {
        if let viewModel = viewModel {
            businessFilesTableViewController?.viewModel = BusinessFilesTableViewController.ViewModel(businessFiles: viewModel.businessFiles, selectedBusinessFile: viewModel.selectedBusinessFile)
        } else {
            businessFilesTableViewController?.viewModel = nil
        }
    }
    
    @IBAction func close(_ sender: Any) {
        onCloseButton?()
    }
}
