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
    var lastFetchDate: Date?
    var businessFiles: [FCLFormsBusinessFile]?
    var selectedBusinessFile: FCLFormsBusinessFile? {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.FCLSelectedBusinessFile, object: nil, userInfo: [FCLSelectedBusinessFileKey: selectedBusinessFile as Any])
        }
    }
    
    lazy var sideTransitioningDelegate = SideTransitioningDelegate()
    
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
        guard let sideViewController = navigationController?.viewControllers.first as? SidePanelViewController else {
            fatalError("SidePanelVC should be on the navigation stack at that point.")
        }
        
        sideViewController.onCloseButton = { [weak self] in
            self?.dismiss()
        }
        sideViewController.onBusinessFileSelection = { [weak self] (businessFile) in
            self?.selectedBusinessFile = businessFile
            self?.dismiss()
        }
        
        if lastFetchDate == nil || (Date().timeIntervalSince(lastFetchDate!) > 60*5) {
            loadBusinessFiles(in: sideViewController)
        } else if let businessFiles = businessFiles,
            let selectedBusinessFile = selectedBusinessFile {
            sideViewController.viewModel = SidePanelViewController.ViewModel(businessFiles: businessFiles, selectedBusinessFile: selectedBusinessFile)
        } else {
            sideViewController.viewModel = nil
        }
        
        navigationController!.modalPresentationStyle = .custom
        navigationController!.transitioningDelegate = sideTransitioningDelegate
        viewController.present(navigationController!, animated: true, completion: nil)
    }
    
    private func loadBusinessFiles(in sideViewController: SidePanelViewController) {
        guard let businessFilesFetch = businessFilesFetch else {
            return
        }
        
        businessFilesFetch.fetchAllSuccess({ [weak self] (businessFiles) in
            self?.lastFetchDate = Date()
            self?.businessFiles = businessFiles
            
            guard businessFiles.count > 0 else {
                sideViewController.viewModel = nil
                return
            }
            
            // If the selected business file is not part of the new list, select the first one from the new list
            let selected: FCLFormsBusinessFile
            if let selectedBusinessFile = self?.selectedBusinessFile {
                if businessFiles.contains(selectedBusinessFile) {
                    selected = selectedBusinessFile
                } else {
                    selected = businessFiles[0]
                }
            } else {
                selected = businessFiles[0]
            }
            sideViewController.viewModel = SidePanelViewController.ViewModel(businessFiles: businessFiles, selectedBusinessFile: selected)
        }, failure: { (error) in
            sideViewController.fcl_presentAlert(forError: error)
        })
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // TODO: pull to refresh
}
