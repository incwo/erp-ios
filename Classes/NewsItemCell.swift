//
//  NewsItemCell.swift
//  facile
//
//  Created by Renaud Pradenc on 28/08/2019.
//

import UIKit

class NewsItemCell: UITableViewCell {
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter
    }()
    
    
    @objc var date: Date? = nil {
        didSet {
            if let date = date {
                dateLabel.text = NewsItemCell.dateFormatter.string(from: date)
            } else {
                dateLabel.text = ""
            }
        }
    }
    
    @objc var title: String? = nil {
        didSet {
            titleLabel.text = title
        }
    }
    
    // TODO: the title should be bold when not read
    @objc var isRead: Bool = false {
        didSet {
            titleLabel.textColor = isRead ? UIColor(white: 0.3, alpha: 1.0) : .black
            titleLabel.font = UIFont.systemFont(ofSize: 15.0, weight: isRead ? .regular : .semibold)
        }
    }
    
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

}
