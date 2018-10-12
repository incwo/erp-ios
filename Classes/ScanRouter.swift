//
//  ScanRouter.swift
//  facile
//
//  Created by Renaud Pradenc on 10/10/2018.
//

import UIKit

@objc
class ScanRouter: NSObject {
    @objc public let navigationController: UINavigationController
    private lazy var loginViewController: FCLLoginController = {
        let loginController = FCLLoginController(delegate: self, email: FCLSession.saved()?.username)
        loginController.title = "Scan"
        return loginController
    }()
    
    @objc override init() {
        navigationController = UINavigationController()
        super.init()
        
        navigationController.viewControllers = [loginViewController];
        if FCLSession.saved() != nil {
            pushContentViewController(animated: false)
        }
        
        // Present the content when the user gets logged in
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { [weak self] (_) in
            self?.pushContentViewController(animated: true)
        }
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.navigationController.popToRootViewController(animated: true)
        }
    }
    
    private func pushContentViewController(animated: Bool) {
        guard let session = FCLSession.saved() else {
            fatalError("It is expected to have a saved Session at this stage")
        }
        
        let contentController = FCLBusinessFilesViewController(session: session)
        navigationController.pushViewController(contentController, animated: animated)
    }
    
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
}

extension ScanRouter: FCLLoginControllerDelegate {    
    func loginControllerWantsAccountCreation(_ controller: FCLLoginController) {
        pushAccountCreationViewController()
    }
    
    func loginControllerDidFail(_ controller: FCLLoginController, error: Error) {
        navigationController.topViewController?.fcl_presentAlert(forError: error)
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
        navigationController.topViewController?.fcl_presentAlert(forError: error)
        navigationController.popViewController(animated: true)
    }
}
