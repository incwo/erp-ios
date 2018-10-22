//
//  SidePanelController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import Foundation
import UIKit

class SidePanelController: NSObject {
    var navigationController: UINavigationController?
    var businessFilesFetch: FCLBusinessFilesFetch?
    
    override init() {
        super.init()
    
        if let session = FCLSession.saved() {
            self.businessFilesFetch = FCLBusinessFilesFetch(session: session)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { [weak self] (_) in
            guard let session = FCLSession.saved() else {
                fatalError()
            }
            
            self?.businessFilesFetch = FCLBusinessFilesFetch(session: session)
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.businessFilesFetch = nil
        }
    }
    
    func present(from viewController: UIViewController) {
        self.navigationController = UIStoryboard.init(name: "SidePanel", bundle: nil).instantiateInitialViewController() as? UINavigationController
        let sideViewController = navigationController?.viewControllers.first as? SidePanelViewController
        sideViewController?.onCloseButton = { [weak self] in
            self?.dismiss()
        }
        viewController.present(navigationController!, animated: true, completion: nil)
        
        if let businessFilesFetch = businessFilesFetch {
            businessFilesFetch.fetchAllSuccess({ (businessFiles) in
                sideViewController?.businessFilesTableViewController?.businessFiles = businessFiles
            }, failure: { (error) in
                viewController.fcl_presentAlert(forError: error)
            })
        }
        
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // TODO: pull to refresh
}
