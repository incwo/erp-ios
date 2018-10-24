//
//  BusinessFilesController.swift
//  facile
//
//  Created by Renaud Pradenc on 24/10/2018.
//

import Foundation

/// Maintains an up-to-date list of Business Files.
class BusinessFilesList {
    enum GetResult {
        case list (businessFiles: [FCLFormsBusinessFile], selection: FCLFormsBusinessFile)
        case loggedOut
        case failure (error: Error)
    }
    
    private var businessFiles: [FCLFormsBusinessFile]?
    private var selection: FCLFormsBusinessFile? {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.FCLSelectedBusinessFile, object: nil, userInfo: [FCLSelectedBusinessFileKey: selection as Any])
        }
    }
    private var businessFilesFetch: FCLBusinessFilesFetch?
    private var lastFetchDate: Date?
    
    init() {
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
    
    public func getBusinessFiles(completion: @escaping (GetResult)->()) {
        guard let businessFilesFetch = businessFilesFetch else {
            completion(.loggedOut)
            return
        }
        
        if isOld() {
            businessFilesFetch.fetchAllSuccess({ [weak self] (businessFiles) in
                guard businessFiles.count > 0 else {
                    completion(.failure(error: NSError(domain: "BusinessFilesList", code: 0, userInfo: [NSLocalizedDescriptionKey: "The server returned an empty list of Business Files"])))
                    return
                }
                
                self?.lastFetchDate = Date()
                self?.businessFiles = businessFiles
                
                // If the current selection is not part of the new list, select the first one from the new list
                if let selection = self?.selection {
                    if !businessFiles.contains(selection) {
                        self?.selection = businessFiles[0]
                    } // else: keep the same selection
                } else { // No selection yet
                    self?.selection = businessFiles[0]
                }

                if let selection = self?.selection { // Should always be true
                    completion(.list(businessFiles: businessFiles, selection: selection))
                }
            }, failure: { (error) in
                completion(.failure(error: error))
                return
            })
        } else {
            guard let businessFiles = businessFiles,
                let selection = selection else {
                    fatalError("A list should have been loaded before")
            }
            completion(.list(businessFiles: businessFiles, selection: selection))
        }
    }
    
    public func selectBusinessFile(_ businessFile: FCLFormsBusinessFile) {
        guard let businessFiles = businessFiles,
            businessFiles.contains(businessFile) else {
            return
        }
        
        selection = businessFile
    }
    
    private func isOld() -> Bool {
        if let lastFetchDate = lastFetchDate {
            return (Date().timeIntervalSince(lastFetchDate) > 60*5)
        } else {
            return true
        }
    }
}
