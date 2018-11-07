//
//  BusinessFile.swift
//  facile
//
//  Created by Renaud Pradenc on 06/11/2018.
//

import Foundation
import SWXMLHash

struct BusinessFile {
    let identifier: String
    let name: String
}

extension BusinessFile: XMLIndexerDeserializable {
    static func deserialize(_ element: XMLIndexer) throws -> BusinessFile {
        return try BusinessFile(
            identifier: element["id"].value(),
            name: element["name"].value()
        )
    }
}
