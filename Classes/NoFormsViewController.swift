//
//  NoFormsViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 07/11/2018.
//

import UIKit

protocol NoFormsViewControllerDelegate: class {
    func noFormsViewControllerSidePanel(_ sender: NoFormsViewController)
}

class NoFormsViewController: UIViewController {
    public weak var delegate: NoFormsViewControllerDelegate?
    public var businessFileName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = businessFileName
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Menu"), style: .plain, target: self, action: #selector(showSidePanel(_:)))
    }
    
    @objc func showSidePanel(_ sender: Any) {
        delegate?.noFormsViewControllerSidePanel(self)
    }

}
