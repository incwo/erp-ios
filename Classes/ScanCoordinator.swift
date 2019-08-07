//
//  ScanCoordinator.swift
//  facile
//
//  Created by Renaud Pradenc on 10/10/2018.
//

import UIKit

protocol ScanCoordinatorDelegate: class {
    func scanCoordinatorPresentSidePanel()
}

class ScanCoordinator: NSObject {
    public weak var delegate: ScanCoordinatorDelegate?
    
    public let navigationController: UINavigationController
    
    override init() {
        self.navigationController = UINavigationController()
        super.init()
        
        defer { // Otherwise, the content would not not be set, because properties observer don't apply in init().
            if FCLSession.saved() == nil {
                self.content = .login
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSelectedBusinessFile, object: nil, queue: nil) { [weak self] (notification) in
            if let businessFileId = notification.userInfo?[FCLSelectedBusinessFileIdKey] as? String {
                let businessFileName = notification.userInfo?[FCLSelectedBusinessFileNameKey] as? String
                DispatchQueue.main.async {
                    self?.content = .loading(businessFileName: businessFileName)
                    self?.fetchFormsBusinessFile(id: businessFileId) { [weak self] (formsBusinessFile) in
                        if let formsBusinessFile = formsBusinessFile {
                            self?.content = .forms(formsBusinessFile: formsBusinessFile)
                        } else {
                            self?.content = .noForms(businessFileName: businessFileName)
                        }
                    }
                }
            }
        }
        
        // Go back to the Root VC (Log in) when the user is signing out
        NotificationCenter.default.addObserver(forName: NSNotification.Name.FCLSessionDidSignOut, object: nil, queue: nil) { [weak self] (notification) in
            self?.businessFilesFetch = nil
            self?.content = .login
        }
    }
    
    // MARK: Content View Controllers
    
    private lazy var scanViewController: UIViewController = {
        return UIViewController()
    }()
    
    private var formListCoordinator: FormListCoordinator? = nil
    
    enum Content {
        case none
        case login
        case loading (businessFileName: String?)
        case noForms (businessFileName: String?)
        case forms (formsBusinessFile: FCLFormsBusinessFile)
    }
    var content: Content = .none {
        didSet {
            switch content {
            case .none:
                contentViewController = nil
            case .login:
                let loginViewController = newLoginViewController()
                contentViewController = loginViewController
                self.loginViewController = loginViewController
            case .loading (let businessFileName):
                contentViewController = newLoadingViewController(businessFileName: businessFileName)
            case .noForms (let businessFileName):
                contentViewController = newNoFormsViewController(businessFileName: businessFileName)
            case .forms (let formsBusinessFile):
                formListCoordinator = FormListCoordinator(delegate: self, navigationController: navigationController, businessFile: formsBusinessFile)
                contentViewController = formListCoordinator!.rootViewController
            }
        }
    }
    
    var contentViewController: UIViewController? {
        willSet {
            contentViewController?.remove()
            loginViewController = nil
        }
        
        didSet {
            if let contentViewController = contentViewController {
                navigationController.viewControllers = [contentViewController]
            } else {
                navigationController.viewControllers = []
            }
        }
    }
    
    private var loginViewController: FCLLoginViewController?
    private func newLoginViewController() -> FCLLoginViewController {
        let loginController = FCLLoginViewController(delegate: self)
        loginController.title = "Scan"
        return loginController
    }
    
    private func newLoadingViewController(businessFileName: String?) -> UIViewController {
        let loadingViewController = UIViewController(nibName: "LoadingViewController", bundle: nil)
        loadingViewController.title = businessFileName
        return loadingViewController
    }
    
    private func newNoFormsViewController(businessFileName: String?) -> UIViewController {
        let noFormsViewController = NoFormsViewController(nibName: nil, bundle: nil)
        noFormsViewController.delegate = self
        noFormsViewController.businessFileName = businessFileName
        return noFormsViewController
    }
    
    // MARK: - View Controllers
    private func pushAccountCreationViewController() {
        let accountCreationController = AccountCreationViewController(delegate: self)
        navigationController.pushViewController(accountCreationController, animated: true)
    }
    
    private func presentAlert(for error: Error) {
        navigationController.topViewController?.fcl_presentAlert(forError: error)
    }
    
    // MARK: - Fetching Form business files
    
    private var businessFilesFetch: FCLFormsBusinessFilesFetch? = nil
    
    private func fetchFormsBusinessFile(id: String, success: @escaping (FCLFormsBusinessFile?)->() ) {
        if businessFilesFetch == nil {
            guard let session = FCLSession.saved() else {
                fatalError("Should be logged in")
            }
            
            self.businessFilesFetch = FCLFormsBusinessFilesFetch(session: session)
        }
        
        businessFilesFetch?.fetchOne(withId: id, success: { (businessFile) in
            success(businessFile)
        }, failure: { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.presentAlert(for: error)
            }
        })
    }
}

// MARK: - Delegation

extension ScanCoordinator: FCLLoginViewControllerDelegate {    
    func loginViewControllerWantsAccountCreation(_ controller: FCLLoginViewController) {
        pushAccountCreationViewController()
    }
}

extension ScanCoordinator: AccountCreationViewControllerDelegate {
    func accountCreationViewControllerDidCreateAccount(_ controller: AccountCreationViewController, email: String) {
        loginViewController?.email = email;
        navigationController.popViewController(animated: true)
    }
    
    func accountCreationViewControllerDidCancel(_ controller: AccountCreationViewController) {
        navigationController.popViewController(animated: true)
    }
    
    func accountCreationViewControllerDidFail(_ controller: AccountCreationViewController, error: NSError) {
        presentAlert(for: error)
        navigationController.popViewController(animated: true)
    }
}

extension ScanCoordinator: NoFormsViewControllerDelegate {
    func noFormsViewControllerSidePanel(_ sender: NoFormsViewController) {
        delegate?.scanCoordinatorPresentSidePanel()
    }
}

extension ScanCoordinator: FormListCoordinatorDelegate {
    func formListCoordinatorPresentSidePanel() {
        delegate?.scanCoordinatorPresentSidePanel()
    }
}


