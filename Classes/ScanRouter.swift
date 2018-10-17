//
//  ScanRouter.swift
//  facile
//
//  Created by Renaud Pradenc on 10/10/2018.
//

import UIKit

protocol ScanRouterDelegate: class {
    func scanRouterDidPresentListOfBusinessFiles()
    func scanRouterDidPresentBusinessFile(identifier: String)
}

@objc
class ScanRouter: NSObject {
    enum State {
        case loggedOut
        case emptyBusinessFilesList(FCLSession)
        case businessFilesList ([FCLBusinessFile])
        case formList(FCLBusinessFile)
        // There are no states for the next view controllers yet (Form, enum picking, signature, etc.)
    }
    
    public weak var delegate: ScanRouterDelegate?
    private var state: State = .loggedOut
    private var businessFilesFetch: FCLBusinessFilesFetch!
    
    @objc public let navigationController: UINavigationController
    private lazy var loginViewController: FCLLoginController = {
        let loginController = FCLLoginController(delegate: self, email: FCLSession.saved()?.username)
        loginController.title = "Scan"
        return loginController
    }()
    private var businessFilesListViewController: FCLBusinessFilesViewController!
    private var formListViewController: FCLFormListViewController!
    
    override init() {
        self.navigationController = UINavigationController()
        super.init()
        
        navigationController.delegate = self
        navigationController.viewControllers = [loginViewController];
        if let session = FCLSession.saved() {
            applyState(.emptyBusinessFilesList(session), animated: false)
        }
        
        // Present the content when the user gets logged in
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { [weak self] (_) in
            guard let session = FCLSession.saved() else {
                fatalError("Should be logged in")
            }
            
            self?.applyState(.emptyBusinessFilesList(session), animated: true)
        }
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.applyState(.loggedOut, animated: true)
        }
    }
    
    public func goToListOfBusinessFiles() {
        switch state {
        case .loggedOut:
            fatalError("The Scan Router is not logged in.")
        case .emptyBusinessFilesList :
            // Do nothing, it must be loading the list
            break
        case .businessFilesList:
            // Do nothing, the list is being shown
            break
        case .formList:
            if let businessFiles = businessFilesListViewController.businessFiles {
                applyState(.businessFilesList(businessFiles), animated: false)
            } else if let session = FCLSession.saved() {
                applyState(.emptyBusinessFilesList(session), animated: false)
            }
        }
    }
    
    public func goToBusinessFile(identifier: String) {
        switch state {
        case .loggedOut:
            fatalError("The Scan Router is not logged in.")
        case .emptyBusinessFilesList, .businessFilesList, .formList:
            fetchBusinessFile(id: identifier) { [weak self] (businessFile) in
                self?.applyState(.formList(businessFile), animated: true)
            }
        }
    }
    
    // MARK: State machine
    private func applyState(_ newState: State, animated: Bool) {
        switch(state) {
        case .loggedOut:
            goFromLoggedOutState(to: newState)
        case .emptyBusinessFilesList:
            goFromEmptyBusinessFilesListState(to: newState)
        case .businessFilesList:
            goFromBusinessFilesListState(to: newState)
        case .formList:
            goFromFormListState(to: newState)
        }
        
        state = newState
    }
    
    private func goFromLoggedOutState(to newState: State) {
        switch newState {
        case .emptyBusinessFilesList (let session):
            pushBusinessFiles(nil, animated: true)
            
            self.businessFilesFetch = FCLBusinessFilesFetch(session: session)
            fetchBusinessFiles { [weak self] (businessFiles) in
                self?.applyState(.businessFilesList(businessFiles), animated: true)
            }
        default:
            fatalError("Unexpected state")
        }
    }
    
    private func goFromEmptyBusinessFilesListState(to newState: State) {
        switch newState {
        case .loggedOut:
            navigationController.popViewController(animated: true)
            businessFilesListViewController = nil
        case .businessFilesList(let businessFiles):
            businessFilesListViewController.businessFiles = businessFiles
        default:
            fatalError("Unexpected state")
        }
    }
    
    private func goFromBusinessFilesListState(to newState: State) {
        switch newState {
        case .loggedOut:
            navigationController.popViewController(animated: true)
        case .businessFilesList(let businessFiles):
            businessFilesListViewController.businessFiles = businessFiles // Refresh the list
        case .formList(let businessFile):
            pushFormList(for: businessFile)
        default:
            fatalError("Unexpected state")
        }
    }
    
    private func goFromFormListState(to newState: State) {
        switch newState {
        case .emptyBusinessFilesList, .businessFilesList:
            // In the Form state, we can be on the FormVC but also on next view controllers
            navigationController.popToViewController(businessFilesListViewController, animated: true)
        case .formList(let businessFile):
            formListViewController.businessFile = businessFile // Refresh the list
            navigationController.popToViewController(formListViewController, animated: true) // If we're on a next view controller
        default:
            fatalError("Unexpected state")
        }
    }
    
    // MARK: Fetching business files
    private func fetchBusinessFiles(success: @escaping ([FCLBusinessFile])->() ) {
        businessFilesFetch.fetchAllSuccess({ (businessFiles) in
            success(businessFiles)
        }, failure: { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.presentAlert(for: error)
            }
        })
    }
    
    private func fetchBusinessFile(id: String, success: @escaping (FCLBusinessFile)->() ) {
        businessFilesFetch.fetchOne(withId: id, success: { (businessFile) in
            success(businessFile)
        }, failure: { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.presentAlert(for: error)
            }
        })
    }
    
    // MARK: View Controllers
    private func pushBusinessFiles(_ businessFiles: [FCLBusinessFile]?, animated: Bool) {
        self.businessFilesListViewController = FCLBusinessFilesViewController(delegate: self)
        businessFilesListViewController.businessFiles = businessFiles
        navigationController.pushViewController(businessFilesListViewController, animated: animated)
    
    }
    
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
    
    private func pushFormList(for businessFile: FCLBusinessFile) {
        guard let session = FCLSession.saved() else {
            fatalError("It is expected to have a saved Session at this stage")
        }
        
        self.formListViewController = FCLFormListViewController(nibName: nil, bundle: nil)
        formListViewController.delegate = self
        formListViewController.businessFile = businessFile
        formListViewController.username = session.username
        formListViewController.password = session.password
        navigationController.pushViewController(formListViewController, animated: true)
    }
    
    private func presentAlert(for error: Error) {
        navigationController.topViewController?.fcl_presentAlert(forError: error)
    }
}

// Interpreting the current view controller on the navigation stack is the easiest way to handle Back button items
extension ScanRouter: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController == businessFilesListViewController {
            if let businessFiles = businessFilesListViewController.businessFiles {
                state = .businessFilesList(businessFiles)
            }
            delegate?.scanRouterDidPresentListOfBusinessFiles()
        } else if viewController == formListViewController {
            if let businessFile = formListViewController.businessFile {
                state = .formList(businessFile)
                delegate?.scanRouterDidPresentBusinessFile(identifier: businessFile.identifier)
            }
        }
    }
}

extension ScanRouter: FCLLoginControllerDelegate {    
    func loginControllerWantsAccountCreation(_ controller: FCLLoginController) {
        pushAccountCreationViewController()
    }
    
    func loginControllerDidFail(_ controller: FCLLoginController, error: Error) {
        presentAlert(for: error)
    }
}

extension ScanRouter: AccountCreationViewControllerDelegate {
    func accountCreationViewControllerDidCreateAccount(_ controller: AccountCreationViewController, email: String) {
        loginViewController.email = email;
        navigationController.popViewController(animated: true)
    }
    
    func accountCreationViewControllerDidCancel(_ controller: AccountCreationViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func accountCreationViewControllerDidFail(_ controller: AccountCreationViewController, error: NSError) {
        presentAlert(for: error)
        navigationController.popViewController(animated: true)
    }
}

extension ScanRouter: FCLBusinessFilesViewControllerDelegate {
    func businessFilesViewControllerRefresh(_ controller: FCLBusinessFilesViewController) {
        fetchBusinessFiles { [weak self] (businessFiles) in
            self?.applyState(.businessFilesList(businessFiles), animated: true)
        }
    }
    
    func businessFilesViewController(_ controller: FCLBusinessFilesViewController, didSelect businessFile: FCLBusinessFile) {
        applyState(.formList(businessFile), animated: true)
    }
    
    func businessFilesViewControllerLogOut(_ controller: FCLBusinessFilesViewController) {
        FCLSession.removeSavedSession() // Emits FCLSessionDidSignOut
    }
}

extension ScanRouter: FCLFormListViewControllerDelegate {
    func formListViewControllerRefresh(_ controller: FCLFormListViewController) {
        fetchBusinessFile(id: controller.businessFile!.identifier) { [weak self] (businessFile) in
            self?.applyState(.formList(businessFile), animated: true)
        }
    }
}
