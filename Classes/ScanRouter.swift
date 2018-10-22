//
//  ScanRouter.swift
//  facile
//
//  Created by Renaud Pradenc on 10/10/2018.
//

import UIKit

protocol ScanRouterDelegate: class {
    func scanRouterPresentSidePanel()
}

@objc
class ScanRouter: NSObject {
    public weak var delegate: ScanRouterDelegate?
    private var businessFilesFetch: FCLBusinessFilesFetch!
    
    @objc public let navigationController: UINavigationController
    private lazy var loginViewController: FCLLoginController = {
        let loginController = FCLLoginController(delegate: self, email: FCLSession.saved()?.username)
        loginController.title = "Scan"
        return loginController
    }()
    private var formListViewController: FCLFormListViewController?
    
    override init() {
        self.navigationController = UINavigationController()
        super.init()
        
        navigationController.viewControllers = [loginViewController];
        
        // TODO: Present the content when the user gets logged in
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { [weak self] (_) in
            guard let session = FCLSession.saved() else {
                fatalError("Should be logged in")
            }
            
            self?.businessFilesFetch = FCLBusinessFilesFetch(session: session)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSelectedBusinessFile, object: nil, queue: nil) { [weak self] (notification) in
            if let businessFile = notification.userInfo?[FCLSelectedBusinessFileKey] as? FCLFormsBusinessFile {
                if let formListViewController = self?.formListViewController {
                    // Come back or stay on the Forms List
                    self?.navigationController.popToViewController(formListViewController, animated: true)
                } else {
                    // We're on the Login VC.
                    self?.pushFormList()
                }
                
                self?.formListViewController?.businessFile = businessFile
            }
        }
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            
            self?.businessFilesFetch = nil
            self?.navigationController.popToRootViewController(animated: true)
            self?.formListViewController = nil
        }
    }
    
    // MARK: Fetching business files
    
    private func fetchBusinessFile(id: String, success: @escaping (FCLFormsBusinessFile)->() ) {
        businessFilesFetch.fetchOne(withId: id, success: { (businessFile) in
            success(businessFile)
        }, failure: { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.presentAlert(for: error)
            }
        })
    }
    
    // MARK: View Controllers
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
    
    private func pushFormList() {
        guard let session = FCLSession.saved() else {
            fatalError("It is expected to have a saved Session at this stage")
        }
        
        self.formListViewController = FCLFormListViewController(nibName: nil, bundle: nil)
        formListViewController!.delegate = self
        formListViewController!.username = session.username
        formListViewController!.password = session.password
        navigationController.pushViewController(formListViewController!, animated: true)
    }
    
    private func presentAlert(for error: Error) {
        navigationController.topViewController?.fcl_presentAlert(forError: error)
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

extension ScanRouter: FCLFormListViewControllerDelegate {
    func formListViewControllerSidePanel(_ controller: FCLFormListViewController) {
        delegate?.scanRouterPresentSidePanel()
    }
    
    func formListViewControllerRefresh(_ controller: FCLFormListViewController) {
        fetchBusinessFile(id: controller.businessFile!.identifier) { [weak self] (businessFile) in
            self?.formListViewController?.businessFile = businessFile
        }
    }
}
