//
//  SidePanelController.swift
//  facile
//
//  Created by Renaud Pradenc on 22/10/2018.
//

import Foundation
import UIKit

class SidePanelController: NSObject {
    let businessFilesList: BusinessFilesList
    var navigationController: UINavigationController?
    lazy var sideTransitioningDelegate = SideTransitioningDelegate()
    var sidePanelViewController: SidePanelViewController?
    
    init(businessFilesList: BusinessFilesList) {
        self.businessFilesList = businessFilesList
        super.init()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignIn, object: nil, queue: nil) { [weak self] (_) in
            self?.updateLoggedInViewModel()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.updateLoggedInViewModel()
            self?.updateBusinessFilesTableView() // To show an empty list
        }
    }
    
    func present(from viewController: UIViewController) {
        self.navigationController = UIStoryboard.init(name: "SidePanel", bundle: nil).instantiateInitialViewController() as? UINavigationController
        guard let sideViewController = navigationController?.viewControllers.first as? SidePanelViewController else {
            fatalError("SidePanelVC should be on the navigation stack at that point.")
        }
        self.sidePanelViewController = sideViewController
        
        sideViewController.onCloseButton = { [weak self] in
            self?.dismiss()
        }
        sideViewController.onBusinessFileSelection = { [weak self] (businessFile) in
            self?.businessFilesList.selectBusinessFile(businessFile)
            self?.updateBusinessFilesTableView()
            self?.dismiss()
        }
        sideViewController.onPullToRefresh = { [weak self] in
            self?.updateBusinessFilesTableView(refresh: true)
        }
        sideViewController.onLogInButton = { [weak self] in
            // Afficher le panneau de login
//            self?.updateLoggedInViewModel(in: sideViewController)
        }
        sideViewController.onLogOutButton = {
            FCLSession.removeSavedSession()
        }
        
        updateLoggedInViewModel()
        updateBusinessFilesTableView()

        
        navigationController!.modalPresentationStyle = .custom
        navigationController!.transitioningDelegate = sideTransitioningDelegate
        viewController.present(navigationController!, animated: true, completion: nil)
    }
    
    private func updateBusinessFilesTableView(refresh: Bool = false) {
        if refresh {
            businessFilesList.invalidateCachedList()
        }
        
        businessFilesList.getBusinessFiles { [weak self] (result) in
            switch result {
            case .list(let businessFiles, let selection):
                self?.sidePanelViewController?.viewModel = SidePanelViewController.ViewModel(businessFiles: businessFiles, selectedBusinessFile: selection)
            case .loggedOut:
                self?.sidePanelViewController?.viewModel = nil
            case .failure(let error):
                self?.sidePanelViewController?.fcl_presentAlert(forError: error)
            }
        }
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
        sidePanelViewController = nil
    }
    
    private func updateLoggedInViewModel() {
        if let session = FCLSession.saved() {
            sidePanelViewController?.loggedViewModel = SidePanelViewController.LoggedViewModel.loggedIn(username: session.username)
        } else {
            sidePanelViewController?.loggedViewModel = SidePanelViewController.LoggedViewModel.loggedOut
        }
    }
}
