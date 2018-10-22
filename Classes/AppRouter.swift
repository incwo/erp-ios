//
//  AppRouter.swift
//  facile
//
//  Created by Renaud Pradenc on 16/10/2018.
//

import Foundation

@objc
class AppRouter: NSObject {
    let rootViewController: UIViewController
    let officeRouter: OfficeRouter
    let scanRouter: ScanRouter
    let sidePanelController: SidePanelController
    
    @objc
    init(rootViewController: UIViewController, officeRouter: OfficeRouter, scanRouter: ScanRouter) {
        self.rootViewController = rootViewController
        self.officeRouter = officeRouter
        self.scanRouter = scanRouter
        self.sidePanelController = SidePanelController()
        super.init()
        
        officeRouter.delegate = self;
        scanRouter.delegate = self
    }
}

extension AppRouter: OfficeRouterDelegate {
    func officeRouterPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
    
    func officeRouterDidPresentListOfBusinessFiles() {
        scanRouter.goToListOfBusinessFiles()
    }
    
    func officeRouterDidPresentBusinessFile(identifier: String) {
        scanRouter.goToBusinessFile(identifier: identifier)
    }
}

extension AppRouter: ScanRouterDelegate {
    func scanRouterPresentSidePanel() {
        sidePanelController.present(from: rootViewController)
    }
    
    func scanRouterDidPresentListOfBusinessFiles() {
        officeRouter.goToListOfBusinessFiles()
    }
    
    func scanRouterDidPresentBusinessFile(identifier: String) {
        officeRouter.goToBusinessFile(id: identifier)
    }
}
