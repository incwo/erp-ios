//
//  BusinessFileFormFetch.swift
//  facile
//
//  Created by Renaud Pradenc on 06/11/2018.
//

import Foundation
import SWXMLHash

class BusinessFilesFetch {
    typealias SuccessHandler = ([BusinessFile])->()
    typealias FailureHandler = (Error)->()
    
    let session: FCLSession
    var successHandler: SuccessHandler!
    var failureHandler: FailureHandler!
    var sessionTask: URLSessionTask?
    
    public init(session: FCLSession) {
        self.session = session
    }
    
    deinit {
        sessionTask?.cancel()
    }
    
    public func fetch(success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        self.successHandler = success
        self.failureHandler = failure
        
        sessionTask?.cancel() // The method might be called while still fetching
        
        guard let url = URL(string: "\(session.facileBaseURL())/account/index/0.xml?target=incwo_erp") else {
            NSLog("\(#function) URL is invalid")
            return
        }
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
            
            do {
                let xml = SWXMLHash.parse(xmlData)
                let businessFiles: [BusinessFile] = try xml["business_files"]["business_file"].value()
                self?.successHandler(businessFiles)
            } catch {
                self?.failureHandler(error)
            }
        })
        sessionTask?.resume()
    }
}


