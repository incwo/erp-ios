//
//  AppRouter.swift
//  facile
//
//  Created by Renaud Pradenc on 16/10/2018.
//

import Foundation

class AppRouter {
    let rootViewController: UIViewController
    let businessFilesList: BusinessFilesList
    let officeRouter: OfficeRouter
    let scanRouter: ScanCoordinator
    let sidePanelController: SidePanelController
    
    init(rootViewController: UIViewController, businessFilesList: BusinessFilesList, sidePanelController: SidePanelController, officeRouter: OfficeRouter, scanRouter: ScanCoordinator) {
        self.rootViewController = rootViewController
        self.businessFilesList = businessFilesList
        self.officeRouter = officeRouter
        self.scanRouter = scanRouter
        self.sidePanelController = sidePanelController
        
        officeRouter.delegate = self;
        scanRouter.delegate = self
        
        // If there is a saved Session, this forces the initial loading.
        // When loaded, the first BusinessFile will be selected and a notification sent.
        forceLoadingBusinessFilesList()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { [weak self] (_) in
            self?.forceLoadingBusinessFilesList()
        }
    }
    
    private func forceLoadingBusinessFilesList() {
        MBProgressHUD.showAdded(to: rootViewController.view, animated: true)
        businessFilesList.getBusinessFiles { [weak self] (_) in
            MBProgressHUD.hide(for: self?.rootViewController.view, animated: true)
        }
    }
}

extension AppRouter: OfficeRouterDelegate {
    func officeRouterPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
}

extension AppRouter: ScanCoordinatorDelegate {
    func scanCoordinatorPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
}
