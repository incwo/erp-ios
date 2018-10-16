//
//  AppRouter.swift
//  facile
//
//  Created by Renaud Pradenc on 16/10/2018.
//

import Foundation

@objc
class AppRouter: NSObject {
    let officeRouter: OfficeRouter
    let scanRouter: ScanRouter
    
    @objc
    init(officeRouter: OfficeRouter, scanRouter: ScanRouter) {
        self.officeRouter = officeRouter
        self.scanRouter = scanRouter
        super.init()
        
        officeRouter.delegate = self;
        scanRouter.delegate = self
    }
}

extension AppRouter: OfficeRouterDelegate {
    func officeRouterDidPresentListOfBusinessFiles() {
        print("officeRouterDidPresentListOfBusinessFiles")
    }
    
    func officeRouterDidPresentBusinessFile(identifier: String) {
        print("officeRouterDidPresentBusinessFile(\(identifier))")
    }
    
    
}

extension AppRouter: ScanRouterDelegate {
    func scanRouterDidPresentListOfBusinessFiles() {
        print("scanRouterDidPresentListOfBusinessFiles")
    }
    
    func scanRouterDidPresentBusinessFile(identifier: String) {
        print("scanRouterDidPresentBusinessFile(\(identifier))")
    }
    
    
}
