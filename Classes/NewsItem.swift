//
//  NewsItem.swift
//  facile
//
//  Created by Renaud Pradenc on 27/08/2019.
//

import UIKit

class NewsItem: NSObject {
    @objc var title: String? = nil
    @objc var html: String? = nil
    @objc var date: Date? = nil
    @objc var uuid: String? = nil // KVC is used on this field
    @objc var url: URL? = nil
    
    @objc func anyFieldSet() -> Bool {
        return (title != nil)
            || (html != nil)
            || (date != nil)
            || (uuid != nil)
            || (url != nil)
    }
}
