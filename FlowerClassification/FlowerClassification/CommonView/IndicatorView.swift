//
//  IndicatorView.swift
//  ChatApp
//
//  Created by Vu Khanh on 10/03/2023.
//

import Foundation
import UIKit
class IndicatorView: UIView {
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()

    init(message: String) {
        super.init(frame: .zero)

        // Configure the activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        addSubview(activityIndicator)

        // Configure the message label
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        messageLabel.textColor = .gray
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        addSubview(messageLabel)

        // Add constraints for the activity indicator
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Add constraints for the message label
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 8),
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func stopAnimation() {
        activityIndicator.stopAnimating()
    }
}
