//
//  BusinessFilesParserTests.swift
//  facilescanTests
//
//  Created by Renaud Pradenc on 24/06/2019.
//

import XCTest

class BusinessFilesParserTests: XCTestCase {
    let sampleXmlData: Data = {
        let bundle: Bundle = Bundle(for: BusinessFilesParserTests.classForCoder())
        let url = bundle.url(forResource: "FormsBusinessFiles", withExtension: "xml")!
        return try! Data(contentsOf: url)
    }()

    func testParsesStructure() {
        let formsBusinessFiles = FCLBusinessFilesParser.businessFiles(fromXMLData: sampleXmlData)
        guard let businessFiles = formsBusinessFiles else {
            XCTFail("Could not convert XML data to Forms business files")
            return
        }
        
        XCTAssertEqual(businessFiles.count, 1)
        guard let formBusinessFile = businessFiles.first else {
            return
        }
        
        XCTAssertEqual(formBusinessFile.identifier, "30")
        XCTAssertEqual(formBusinessFile.name, "incwo")
        XCTAssertEqual(formBusinessFile.kind, "Bureau Virtuel")
        
        XCTAssertEqual(formBusinessFile.children.count, 7)
    }
    
    func testParsesSingleProposalSheet() {
        guard let formsBusinessFiles = FCLBusinessFilesParser.businessFiles(fromXMLData: sampleXmlData),
            let businessFile = formsBusinessFiles.first,
            let proposalForm = businessFile.children.last as? FCLForm
        else {
                XCTFail("Error parsing XML")
                return
        }
        
        XCTAssertEqual(proposalForm.key, "proposal_sheets+3003726")
        XCTAssertEqual(proposalForm.name, "Signer le BL BL1612-00224")
        XCTAssertEqual(proposalForm.fields.count, 1)
        
        guard let field = proposalForm.fields.first else {
            XCTFail("Error parsing XML")
            return
        }
        
        XCTAssertEqual(field.name, "Signature")
        XCTAssertEqual(field.key, "my_signature")
        XCTAssertEqual(field.type, .signature)
        XCTAssertEqual(field.fieldDescription, "Je valide la livraison BL1612-00224")
    }
    
    func testParsesFormFolder() {
        guard let formsBusinessFiles = FCLBusinessFilesParser.businessFiles(fromXMLData: sampleXmlData),
            let businessFile = formsBusinessFiles.first,
            let folder = businessFile.children[5] as? FCLFormFolder
            else {
                XCTFail("Error parsing XML")
                return
        }
        
        XCTAssertEqual(folder.title, "Bons de livraison à signer")
        XCTAssertEqual(folder.forms.count, 11)
        
        guard let form = folder.forms.first else {
            XCTFail("FCLFormFolder.forms were not parsed.")
            return
        }
        XCTAssertEqual(form.name, "Signer le BL BL1906-00242")
    }
}
