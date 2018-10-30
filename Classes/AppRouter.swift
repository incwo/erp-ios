//
//  AppRouter.swift
//  facile
//
//  Created by Renaud Pradenc on 16/10/2018.
//

import Foundation

class AppRouter {
    let rootViewController: UIViewController
    let officeRouter: OfficeRouter
    let scanRouter: ScanRouter
    let sidePanelController: SidePanelController
    
    init(rootViewController: UIViewController, businessFilesList: BusinessFilesList, sidePanelController: SidePanelController, officeRouter: OfficeRouter, scanRouter: ScanRouter) {
        self.rootViewController = rootViewController
        self.officeRouter = officeRouter
        self.scanRouter = scanRouter
        self.sidePanelController = sidePanelController
        
        officeRouter.delegate = self;
        scanRouter.delegate = self
        
        // If there is a saved Session, this forces the initial loading.
        // When loaded, the first BusinessFile will be selected and a notification sent.
        businessFilesList.getBusinessFiles { (_) in }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { (_) in
            // Force loading business files after logging in
            businessFilesList.getBusinessFiles { (_) in }
        }
    }
}

extension AppRouter: OfficeRouterDelegate {
    func officeRouterPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
}

extension AppRouter: ScanRouterDelegate {
    func scanRouterPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
}
