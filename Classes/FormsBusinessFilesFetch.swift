//
//  FormsBusinessFilesFetch.swift
//  facile
//
//  Created by Renaud Pradenc on 07/08/2019.
//

import Foundation

class FormsBusinessFilesFetch {
    typealias SuccessHandler = ([FCLFormsBusinessFile])->()
    typealias FailureHandler = (Error)->()
    
    let session: FCLSession
    var successHandler: SuccessHandler!
    var failureHandler: FailureHandler!
    var sessionTask: URLSessionTask?
    
    init(session: FCLSession) {
        self.session = session
    }
    
    deinit {
        sessionTask?.cancel()
    }
    
    func fetchAll(success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        self.successHandler = success
        self.failureHandler = failure
        
        sessionTask?.cancel() // The method might be called while still fetching
        
        guard let url = FormsBusinessFilesFetch.url(session: session) else {
            NSLog("\(#function) URL is invalid")
            return
        }
        loadBusinessFiles(at: url)
    }
    
    func fetchOne(businessFileId: String, success: @escaping (FCLFormsBusinessFile?)->(), failure: @escaping FailureHandler) {
        self.successHandler = { (businessFiles) in
            success(businessFiles.count > 0 ? businessFiles.first : nil)
        }
        self.failureHandler = failure
        
        sessionTask?.cancel() // The method might be called while still fetching
        
        guard let url = FormsBusinessFilesFetch.url(session: session, businessFileId: businessFileId) else {
            NSLog("\(#function) URL is invalid")
            return
        }
        loadBusinessFiles(at: url)
    }
    
    private func loadBusinessFiles(at url: URL) {
        var request = URLRequest(url: url)
        request.setBasicAuthHeader(username: session.username, password: session.password)
        sessionTask = URLSession(configuration: .default).dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            if let error = error {
                self?.failureHandler(error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let error = NSError(domain: "BusinessFilesFetch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server responded with a \(httpResponse.statusCode) status code."])
                self?.failureHandler(error)
                return
            }
            
            guard let xmlData = data else {
                return
            }
            guard let businessFiles = FCLBusinessFilesParser.businessFiles(fromXMLData: xmlData) else {
                let error = NSError(domain: "FormsBusinessFilesFetch", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not parse the Business Files XML data."])
                self?.failureHandler(error)
                return
            }
            
            self?.successHandler(businessFiles)
        })
        sessionTask?.resume()
    }
    
    private static func url(session: FCLSession) -> URL? {
        let base = session.facileBaseURL()
        let urlRandomization = Int32.random(in: 0..<Int32.max)
        return URL(string: base + "/account/get_files_and_image_enabled_objects/0.xml?r=\(urlRandomization)")
    }
    
    private static func url(session: FCLSession, businessFileId: String) -> URL? {
        let base = session.facileBaseURL()
        let urlRandomization = Int32.random(in: 0..<Int32.max)
        
        // r: Makes the URL random so it is not cached (used to cause problems with Orange)
        // filed_id: the business file identifier
        // hierarchical : Asks that the numerous objects of the same types are grouped in folders
        return URL(string: base + "/account/get_files_and_image_enabled_objects/0.xml?r=\(urlRandomization)&file_id=\(businessFileId)&hierarchical=1")
    }
    
}
