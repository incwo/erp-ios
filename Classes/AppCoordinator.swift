//
//  AppCoordinator.swift
//  facile
//
//  Created by Renaud Pradenc on 16/10/2018.
//

import Foundation

class AppCoordinator {
    let rootViewController: UIViewController
    let businessFilesList: BusinessFilesList
    let officeCoordinator: OfficeCoordinator
    let scanCoordinator: ScanCoordinator
    let sidePanelController: SidePanelController
    
    init(rootViewController: UIViewController, businessFilesList: BusinessFilesList, sidePanelController: SidePanelController, officeCoordinator: OfficeCoordinator, scanCoordinator: ScanCoordinator) {
        self.rootViewController = rootViewController
        self.businessFilesList = businessFilesList
        self.officeCoordinator = officeCoordinator
        self.scanCoordinator = scanCoordinator
        self.sidePanelController = sidePanelController
        
        officeCoordinator.delegate = self;
        scanCoordinator.delegate = self
        
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

extension AppCoordinator: OfficeCoordinatorDelegate {
    func officeCoordinatorPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
}

extension AppCoordinator: ScanCoordinatorDelegate {
    func scanCoordinatorPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
}
