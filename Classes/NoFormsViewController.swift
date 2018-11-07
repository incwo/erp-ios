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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }

}
