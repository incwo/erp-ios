//
//  URLRequest+BasicAuth.swift
//  facile
//
//  Created by Renaud Pradenc on 06/11/2018.
//

import Foundation

extension URLRequest {
    mutating func setBasicAuthHeader(username: String, password: String) {
        guard let data = "\(username):\(password)".data(using: .utf8, allowLossyConversion: false) else {
            NSLog("\(#function) Could not convert string to UTF8.")
            return
        }
        
        let value = "Basic " + data.base64EncodedString()
        self.setValue(value, forHTTPHeaderField: "Authorization")
    }
}
