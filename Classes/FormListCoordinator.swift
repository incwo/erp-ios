//
//  FormListCoordinator.swift
//  facile
//
//  Created by Renaud Pradenc on 25/06/2019.
//

import Foundation
import UIKit

protocol FormListCoordinatorDelegate: class {
    func formListCoordinatorPresentSidePanel()
}

class FormListCoordinator: NSObject {
    weak var delegate: FormListCoordinatorDelegate?
    let navigationController: UINavigationController
    let businessFile: FCLFormsBusinessFile
    
    private lazy var formListViewController: FCLFormListViewController = {
        let formListViewController = FCLFormListViewController(nibName: nil, bundle: nil)
        formListViewController.delegate = self
        formListViewController.formsBusinessFile = businessFile
        return formListViewController;
    }()
    public var rootViewController: UIViewController {
        get {
            return formListViewController
        }
    }
    
    init(delegate: FormListCoordinatorDelegate, navigationController: UINavigationController, businessFile: FCLFormsBusinessFile) {
        
        self.delegate = delegate
        self.navigationController = navigationController
        self.businessFile = businessFile
    }
    
    private func present(form: FCLForm) {
        form.reset()
        form.loadDefaults()
        
        let formController = FCLFormViewController(nibName: nil, bundle: nil)
        formController.delegate = self
        formController.form = form
        
        navigationController.pushViewController(formController, animated: true)
    }
    
    lazy private var businessFilesFetch: FCLFormsBusinessFilesFetch = {
        guard let session = FCLSession.saved() else {
            fatalError("Should be logged in")
        }
        return FCLFormsBusinessFilesFetch(session: session)
    }()
    
    private func fetchFormsBusinessFile(id: String, success: @escaping (FCLFormsBusinessFile?)->() ) {
        businessFilesFetch.fetchOne(withId: id, success: { (businessFile) in
            success(businessFile)
        }, failure: { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.rootViewController.fcl_presentAlert(forError: error)
            }
        })
    }
}

extension FormListCoordinator: FCLFormListViewControllerDelegate {
    func formListViewControllerSidePanel(_ controller: FCLFormListViewController) {
        delegate?.formListCoordinatorPresentSidePanel()
    }
    
    func formListViewControllerRefresh(_ controller: FCLFormListViewController) {
        guard let currentBusinessFile = controller.formsBusinessFile else {
            fatalError()
        }
        
        fetchFormsBusinessFile(id: currentBusinessFile.identifier) { [weak self] (businessFile) in
            self?.formListViewController.formsBusinessFile = businessFile
        }
    }
    
    func formListViewController(_ controller: FCLFormListViewController, didSelect form: FCLForm) {
        present(form: form)
    }
}

extension FormListCoordinator: FCLFormViewControllerDelegate {
    func formViewControllerSend(_ formViewController: FCLFormViewController!) {
        navigationController.popViewController(animated: true)
        
        guard let session = FCLSession.saved() else {
            NSLog("\(#function) No current session! The form is not sent.")
            return
        }
        
        let upload = FCLUpload()
        formViewController.form.saveDefaults()
        
        if let formName = formViewController.form.name,
            let formKey = formViewController.form.key {
            NSLog("Sending form \(formName) (\(formKey)) to business_file \(businessFile.name) (\(businessFile.identifier))")
        }
        
        
        upload.fileId = businessFile.identifier
        upload.categoryKey = formViewController.form.key
        upload.fields = formViewController.form?.fields
        upload.image = formViewController.image
        upload.username = session.username
        upload.password = session.password
        
        FCLUploader.shared()?.add(upload)
    }
    
    
}
