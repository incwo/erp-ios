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
    var businessFile: FCLFormsBusinessFile
    
    private lazy var formListViewController: FCLFormListViewController = {
        let formListViewController = FCLFormListViewController(nibName: nil, bundle: nil)
        formListViewController.delegate = self
        formListViewController.sidePanelButtonShown = true
        formListViewController.title = businessFile.name
        formListViewController.formsAndFolders = businessFile.children
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
        super.init()
        
        FCLUploader.shared()?.delegate = self
    }
    
    deinit {
        FCLUploader.shared()?.delegate = nil
    }
    
    private func presentAlert(for error: Error) {
        navigationController.topViewController?.fcl_presentAlert(forError: error)
    }
    
    private func present(form: FCLForm) {
        form.reset()
        form.loadDefaults()
        
        let formController = FCLFormViewController(nibName: nil, bundle: nil)
        formController.delegate = self
        formController.form = form
        
        navigationController.pushViewController(formController, animated: true)
    }
    
    private func present(folder: FCLFormFolder, sidePanelButtonShown: Bool) {
        let formListController = FCLFormListViewController(nibName: nil, bundle: nil)
        formListController.delegate = self
        formListController.sidePanelButtonShown = sidePanelButtonShown
        formListController.title = folder.title
        formListController.formsAndFolders = folder.forms
        
        navigationController.pushViewController(formListController, animated: true)
    }
    
    lazy private var businessFilesFetch: FormsBusinessFilesFetch = {
        guard let session = FCLSession.saved() else {
            fatalError("Should be logged in")
        }
        return FormsBusinessFilesFetch(session: session)
    }()
    
    private func fetchFormsBusinessFile(id: String, success: @escaping (FCLFormsBusinessFile?)->() ) {
        businessFilesFetch.fetchOne(businessFileId: id, success: { (businessFile) in
            success(businessFile)
        }, failure: { (error) in
            DispatchQueue.main.async { [weak self] in
                self?.presentAlert(for: error)
            }
        })
    }
}

extension FormListCoordinator: FCLFormListViewControllerDelegate {
    func formListViewControllerSidePanel(_ controller: FCLFormListViewController) {
        delegate?.formListCoordinatorPresentSidePanel()
    }
    
    func formListViewControllerRefresh(_ controller: FCLFormListViewController) {
        fetchFormsBusinessFile(id: businessFile.identifier) { [weak self] (freshBusinessFile) in
            if let freshBusinessFile = freshBusinessFile {
                self?.businessFile = freshBusinessFile
                DispatchQueue.main.async {
                    self?.formListViewController.title = freshBusinessFile.name
                    self?.formListViewController.formsAndFolders = freshBusinessFile.children
                }
            }
        }
    }
    
    func formListViewController(_ controller: FCLFormListViewController, didSelect form: FCLForm) {
        present(form: form)
    }
    
    func formListViewController(_ controller: FCLFormListViewController, didSelect formFolder: FCLFormFolder) {
        present(folder: formFolder, sidePanelButtonShown: false)
    }
}

extension FormListCoordinator: FCLFormViewControllerDelegate {
    func formViewControllerSend(_ formViewController: FCLFormViewController!) {
        navigationController.popViewController(animated: true)
        
        formViewController.form.saveDefaults()
        send(form: formViewController.form, image: formViewController.image)
    }
    
    private func send(form: FCLForm, image: UIImage?) {
        guard let session = FCLSession.saved() else {
            NSLog("\(#function) No current session! The form won't be sent.")
            return
        }
        
        if let formName = form.name,
            let formKey = form.key {
            NSLog("Sending form \(formName) (\(formKey)) to business_file \(businessFile.name) (\(businessFile.identifier))")
        }
        
        let upload = FCLUpload()
        upload.fileId = businessFile.identifier
        upload.categoryKey = form.key
        upload.fields = form.fields
        upload.image = image
        upload.session = session
        
        FCLUploader.shared()?.add(upload)
    }
}

extension FormListCoordinator: FCLUploaderDelegate {
    func uploaderDidUpdateStatus(_ uploader: FCLUploader!) {
        NSLog("uploaderDidUpdateStatus: isUploading: \(uploader.isUploading())");
    }
    
    func uploader(_ uploader: FCLUploader!, didFailWithError error: Error!) {
        DispatchQueue.main.async {
            self.presentAlert(for: error)
        }
    }
}
