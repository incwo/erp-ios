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
        let loginController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as! FCLLoginController
        loginController.email = FCLSession.saved()?.username
        loginController.completionHandler = { [weak self] (session, error) in
            if session != nil {
                self?.pushContentViewController(animated: true)
            }
        }
        return loginController
    }()
    
    @objc override init() {
        navigationController = UINavigationController()
        super.init()
        
        navigationController.viewControllers = [loginViewController];
        if let session = FCLSession.saved(), session.isValid() {
            pushContentViewController(animated: false)
        }
    }
    
    private func pushContentViewController(animated: Bool) {
        let contentController = FCLOfficeContentViewController(nibName: nil, bundle: nil)
        contentController.delegate = self
        contentController.session = FCLSession.saved()
        
        navigationController.pushViewController(contentController, animated: animated)
    }
}

extension OfficeRouter: FCLOfficeContentViewControllerDelegate {
    func officeContentViewControllerDidLogOut(_ controller: FCLOfficeContentViewController!) {
        navigationController.popViewController(animated: true)
    }
}
