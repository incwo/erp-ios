//
//  BusinessFileFormFetch.swift
//  facile
//
//  Created by Renaud Pradenc on 06/11/2018.
//

import Foundation
import SWXMLHash

class BusinessFilesFetch: NSObject { // Inherits NSObject because it is necessary for OAHTTPDownloadDelegate
    typealias SuccessHandler = ([BusinessFile])->()
    typealias FailureHandler = (Error)->()
    
    let session: FCLSession
    var successHandler: SuccessHandler!
    var failureHandler: FailureHandler!
    var download: OAHTTPDownload?
    
    public init(session: FCLSession) {
        self.session = session
        
        super.init()
    }
    
    deinit {
        download?.cancel()
    }
    
    public func fetch(success: @escaping SuccessHandler, failure: @escaping FailureHandler) {
        self.successHandler = success
        self.failureHandler = failure
        
        download?.cancel() // The method might be called while still fetching
        
        guard let url = URL(string: "\(session.facileBaseURL())/account/index/0.xml") else {
            NSLog("\(#function) URL is invalid")
            return
        }
        var request = URLRequest(url: url)
        request.setBasicAuthHeader(username: session.username, password: session.password)
        
        download = OAHTTPDownload.download(with: request)
        download!.username = session.username
        download!.password = session.password
        download!.delegate = self
        download!.shouldAllowSelfSignedCert = true
        download!.start()
    }
}

extension BusinessFilesFetch: OAHTTPDownloadDelegate {
    func oadownloadDidFinishLoading(_ download: OAHTTPDownloadProtocol!) {
        guard let xmlData = download.receivedData() else {
            failureHandler(NSError(domain: "\(#file)", code: 0, userInfo: [NSLocalizedDescriptionKey: "Empty XML data received."]))
            return
        }
        
        do {
            let xml = SWXMLHash.parse(xmlData)
            let businessFiles: [BusinessFile] = try xml["business_files"]["business_file"].value()
            successHandler(businessFiles)
        } catch {
            failureHandler(error)
        }
    }
    
    func oadownload(_ download: OAHTTPDownloadProtocol!, didFailWithError error: Error!) {
        failureHandler(error)
    }
}


