//
//  OfficeViewController.swift
//  facile
//
//  Created by Renaud Pradenc on 09/10/2018.
//

import UIKit

class OfficeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let contentController = FCLOfficeContentViewController(nibName: nil, bundle: nil)
        addFilling(contentController)
    }
}
