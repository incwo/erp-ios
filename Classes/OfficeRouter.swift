//
//  OfficeViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 09/10/2018.
//

import UIKit

protocol OfficeRouterDelegate: class {
    func officeRouterPresentSidePanel()
    func officeRouterDidPresentListOfBusinessFiles()
    func officeRouterDidPresentBusinessFile(identifier: String)
}

@objc
class OfficeRouter: NSObject {
    public weak var delegate: OfficeRouterDelegate?
    @objc public let navigationController: UINavigationController
    private lazy var loginViewController: FCLLoginController = {
        let loginController = FCLLoginController(delegate: self, email: FCLSession.saved()?.username)
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
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.navigationController.popToRootViewController(animated: true)
        }
    }
    
    public func goToListOfBusinessFiles() {
        contentViewController?.loadHomepage()
    }
    
    public func goToBusinessFile(id: String) {
        // Showing a business file
        if let currentUrl = contentViewController?.currentURL(),
            let currentId = businessFileId(from: currentUrl) {
            if currentId != id { // Different business file
                contentViewController?.loadBusinessFile(withId: id)
            }
        } else { // Not a business file
            contentViewController?.loadBusinessFile(withId: id)
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
        
        contentViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "Menu"), style: .plain, target: self, action: #selector(showSidePanel))
    }
    
    @objc public func showSidePanel() {
        delegate?.officeRouterPresentSidePanel()
    }
    
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
    
    private func didPresentContent(url: URL) {
        // Analyzing URLs is probably a little dangerous since they could change.
        // It's OK for now, since we don't have other mechanisms anyway.
        if isBusinessFilesListUrl(url) {
            delegate?.officeRouterDidPresentListOfBusinessFiles()
        } else if let id = businessFileId(from: url) {
            delegate?.officeRouterDidPresentBusinessFile(identifier: id)
        }
    }
    
    // E.g. https://www.incwo.com/account/index/0#___1__
    private func isBusinessFilesListUrl(_ url: URL) -> Bool {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }
        
        return components.host == "www.incwo.com" && components.path == "/account/index/0"
    }
    
    // E.g.: https://www.incwo.com/navigation_mobile/home/30#_wall_1-
    private func businessFileId(from url: URL) -> String? {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
            components.host == "www.incwo.com",
            let path = components.path,
            path.hasPrefix("/navigation_mobile/home")
            else {
                return nil
        }
        
        return (path as NSString).lastPathComponent
    }
}

extension OfficeRouter: FCLLoginControllerDelegate {
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

extension OfficeRouter: FCLOfficeContentViewControllerDelegate {
    func officeContentViewController(_ controller: FCLOfficeContentViewController, didPresent url: URL) {
        didPresentContent(url: url)
    }
}
