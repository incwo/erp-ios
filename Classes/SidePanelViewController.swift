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
    
    enum LoggedViewModel {
        case loggedIn (username: String)
        case loggedOut
    }
    
    public var viewModel: ViewModel? {
        didSet {
            setBusinessFilesTableViewControllerViewModel()
        }
    }
    
    public var loggedViewModel: LoggedViewModel = .loggedOut {
        didSet {
            applyLoggedViewModel()
        }
    }
    
    public var onCloseButton: ( ()->() )?
    public var onBusinessFileSelection: ( (FCLFormsBusinessFile) -> () )? {
        didSet {
            businessFilesTableViewController?.onSelection = onBusinessFileSelection
        }
    }
    public var onPullToRefresh: ( ()->() )? {
        didSet {
            businessFilesTableViewController?.onPullToRefresh = onPullToRefresh
        }
    }
    
    public var onLogInButton: ( ()->() )? {
        didSet {
            loggedOutViewController?.onLogInButton = onLogInButton
        }
    }
    
    public var onLogOutButton: ( ()->() )? {
        didSet {
            loggedInViewController?.onLogOutButton = onLogOutButton
        }
    }

    private var businessFilesTableViewController: BusinessFilesTableViewController?
    private var loggedInViewController: LoggedInViewController?
    private var loggedOutViewController: LoggedOutViewController?

    // MARK: Outlets
    @IBOutlet weak var loggedContainerView: UIView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        applyLoggedViewModel()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "EmbedBusinessFiles":
            self.businessFilesTableViewController = segue.destination as? BusinessFilesTableViewController
            setBusinessFilesTableViewControllerViewModel()
            businessFilesTableViewController!.onSelection = onBusinessFileSelection
            businessFilesTableViewController!.onPullToRefresh = onPullToRefresh
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
    
    // MARK: Logged panel
    
    private func applyLoggedViewModel() {
        guard isViewLoaded else {
            return
        }
        
        switch loggedViewModel {
        case .loggedIn(let username):
            addLoggedInViewController(username: username)
        case .loggedOut:
            addLoggedOutViewController()
        }
    }
    
    private func addLoggedInViewController(username: String) {
        loggedOutViewController?.remove()
        loggedOutViewController = nil
        
        self.loggedInViewController = storyboard?.instantiateViewController(withIdentifier: "loggedIn") as? LoggedInViewController
        loggedInViewController!.username = username
        loggedInViewController!.onLogOutButton = onLogOutButton
        add(loggedInViewController!, into: loggedContainerView)
    }
    
    private func addLoggedOutViewController() {
        loggedInViewController?.remove()
        loggedInViewController = nil
        
        self.loggedOutViewController = storyboard?.instantiateViewController(withIdentifier: "loggedOut") as? LoggedOutViewController
        loggedOutViewController!.onLogInButton = onLogInButton
        add(loggedOutViewController!, into: loggedContainerView)
    }
}


