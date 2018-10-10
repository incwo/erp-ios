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
        let loginController = FCLLoginController(eMail: FCLSession.saved()?.username, success: { [weak self] (session) in
            if session != nil {
                self?.pushContentViewController(animated: true)
            }
            }, failure: { [weak self] (error) in
                self?.navigationController.topViewController?.fcl_presentAlert(forError: error)
        })
        
        loginController.title = "Scan"
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
        let contentController = FCLScanViewController(nibName: nil, bundle: nil)
        contentController.session = FCLSession.saved()
        
        navigationController.pushViewController(contentController, animated: animated)
    }
}
