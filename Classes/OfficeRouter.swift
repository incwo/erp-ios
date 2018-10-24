//
//  OfficeViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 09/10/2018.
//

import UIKit

protocol OfficeRouterDelegate: class {
    func officeRouterPresentSidePanel()
}

@objc
class OfficeRouter: NSObject {
    public weak var delegate: OfficeRouterDelegate?
    @objc public let navigationController: UINavigationController
    private lazy var loginViewController: FCLLoginViewController = {
        let loginController = FCLLoginViewController(delegate: self, email: FCLSession.saved()?.username)
        loginController.title = "Bureau"
        return loginController
    }()
    private var contentViewController: FCLOfficeContentViewController? = nil
    
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
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSelectedBusinessFile, object: nil, queue: nil) { [weak self] (notification) in
            if let businessFile = notification.userInfo?[FCLSelectedBusinessFileKey] as? FCLFormsBusinessFile {
                if let contentViewController = self?.contentViewController {
                    contentViewController.loadBusinessFile(withId: businessFile.identifier)
                } else {
                    self?.pushContentViewController(animated: true)
                    self?.contentViewController?.loadBusinessFile(withId: businessFile.identifier)
                }
            }
        }
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.navigationController.popToRootViewController(animated: true)
            self?.contentViewController = nil
        }
    }
    
    private func pushContentViewController(animated: Bool) {
        guard let session = FCLSession.saved() else {
            fatalError("There must be a session opened at that point")
        }
        
        self.contentViewController = FCLOfficeContentViewController(nibName: nil, bundle: nil)
        contentViewController!.delegate = self
        contentViewController!.session = session
        navigationController.pushViewController(contentViewController!, animated: animated)
    }
    
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
}

extension OfficeRouter: FCLLoginViewControllerDelegate {
    func loginViewControllerWantsAccountCreation(_ controller: FCLLoginViewController) {
        pushAccountCreationViewController()
    }
    
    func loginViewControllerDidFail(_ controller: FCLLoginViewController, error: Error) {
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

extension OfficeRouter: FCLOfficeContentViewControllerDelegate {
    func officeContentViewControllerPresentSidePanel(_ controller: FCLOfficeContentViewController) {
        delegate?.officeRouterPresentSidePanel()
    }
    
    func officeContentViewController(_ controller: FCLOfficeContentViewController, didPresent url: URL) {
        
    }
}
