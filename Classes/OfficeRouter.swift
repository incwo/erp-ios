//
//  OfficeViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 09/10/2018.
//

import UIKit

@objc
class OfficeRouter: NSObject {
    @objc public let navigationController: UINavigationController
    private lazy var loginViewController: FCLLoginController = {
        let loginController = FCLLoginController(delegate: self, email: FCLSession.saved()?.username)
        loginController.title = "Bureau"
        return loginController
    }()
    
    @objc override init() {
        navigationController = UINavigationController()
        super.init()
        
        navigationController.viewControllers = [loginViewController];
        if let session = FCLSession.saved(), session.isValid() {
            pushContentViewController(animated: false)
        }
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.navigationController.popToRootViewController(animated: true)
        }
    }
    
    private func pushContentViewController(animated: Bool) {
        let contentController = FCLOfficeContentViewController(nibName: nil, bundle: nil)
        contentController.session = FCLSession.saved()
        
        navigationController.pushViewController(contentController, animated: animated)
    }
    
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
}

extension OfficeRouter: FCLLoginControllerDelegate {
    func loginControllerDidLog(in controller: FCLLoginController, session: FCLSession) {
        pushContentViewController(animated: true)
    }
    
    func loginControllerWantsAccountCreation(_ controller: FCLLoginController) {
        pushAccountCreationViewController()
    }
    
    func loginControllerDidFail(_ controller: FCLLoginController, error: Error) {
        navigationController.topViewController?.fcl_presentAlert(forError: error)
    }
}

extension OfficeRouter: AccountCreationViewControllerDelegate {
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
