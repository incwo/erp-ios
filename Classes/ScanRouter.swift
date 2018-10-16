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
    public weak var delegate: ScanRouterDelegate?
    @objc public let navigationController: UINavigationController
    private lazy var loginViewController: FCLLoginController = {
        let loginController = FCLLoginController(delegate: self, email: FCLSession.saved()?.username)
        loginController.title = "Scan"
        return loginController
    }()
    private var businessFilesFetch: FCLBusinessFilesFetch!
    
    override init() {
        self.navigationController = UINavigationController()
        super.init()
        
        navigationController.delegate = self
        navigationController.viewControllers = [loginViewController];
        if FCLSession.saved() != nil {
            pushBusinessFilesViewController(animated: false)
        }
        
        // Present the content when the user gets logged in
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { [weak self] (_) in
            self?.pushBusinessFilesViewController(animated: true)
        }
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.navigationController.popToRootViewController(animated: true)
        }
    }
    
    private func pushBusinessFilesViewController(animated: Bool) {
        guard let session = FCLSession.saved() else {
            fatalError("It is expected to have a saved Session at this stage")
        }
        self.businessFilesFetch = FCLBusinessFilesFetch(session: session)
        
        let businessFilesController = FCLBusinessFilesViewController(delegate: self)
        navigationController.pushViewController(businessFilesController, animated: animated)
        provideBusinessFiles(to: businessFilesController)
    }
    
    private func provideBusinessFiles(to controller: FCLBusinessFilesViewController) {
        businessFilesFetch.fetchSuccess({ (businessFiles) in
            controller.businessFiles = businessFiles
        }, failure: { (error) in
            controller.businessFiles = nil
            DispatchQueue.main.async { [weak self] in
                self?.presentAlert(for: error)
            }
        })
    }
    
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
    
    private func pushCategoriesViewController(for businessFile: FCLBusinessFile) {
        guard let session = FCLSession.saved() else {
            fatalError("It is expected to have a saved Session at this stage")
        }
        
        let categoriesController = FCLScanCategoriesController(nibName: nil, bundle: nil)
        categoriesController.delegate = self
        categoriesController.businessFile = businessFile
        categoriesController.username = session.username
        categoriesController.password = session.password
        navigationController.pushViewController(categoriesController, animated: true)
    }
    
    private func refreshCategoriesViewController(_ categoriesController: FCLScanCategoriesController) {
        guard let currentBusinessFile = categoriesController.businessFile else {
            fatalError("A business file should be currently shown.")
        }
        
        self.businessFilesFetch.fetchSuccess({ [weak self] (businessFiles) in
            if let refreshedBusinessFile = businessFiles.first(where: { $0.identifier == currentBusinessFile.identifier }) {
                categoriesController.businessFile = refreshedBusinessFile
            } else { // The business file is absent from the new list
                self?.navigationController.popViewController(animated: true)
            }
        }, failure: { [weak self] (error) in
            self?.presentAlert(for: error)
        })
    }
    
    private func presentAlert(for error: Error) {
        navigationController.topViewController?.fcl_presentAlert(forError: error)
    }
}

extension ScanRouter: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is FCLBusinessFilesViewController {
            delegate?.scanRouterDidPresentListOfBusinessFiles()
        } else if viewController is FCLScanCategoriesController {
            let scanCategoriesController = viewController as! FCLScanCategoriesController
            if let identifier = scanCategoriesController.businessFile?.identifier {
                delegate?.scanRouterDidPresentBusinessFile(identifier: identifier)
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
        provideBusinessFiles(to: controller)
    }
    
    func businessFilesViewController(_ controller: FCLBusinessFilesViewController, didSelect businessFile: FCLBusinessFile) {
        pushCategoriesViewController(for: businessFile)
    }
    
    func businessFilesViewControllerLogOut(_ controller: FCLBusinessFilesViewController) {
        FCLSession.removeSavedSession() // Emits FCLSessionDidSignOut
    }
}

extension ScanRouter: FCLScanCategoriesControllerDelegate {
    func scanCategoriesControllerRefresh(_ controller: FCLScanCategoriesController) {
        refreshCategoriesViewController(controller);
    }
}
