//
//  NotificationCell.swift
//  Notes
//
//  Created by Ghullam Abbas on 02/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

import UIKit

class NotificationCell: UITableViewCell {
    static let identifier = "NotificationCell"
    
    // Profile image view
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 20 // Rounded for profile image
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Notification message label
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = ApplazAppearance.font(14)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Add profile image and message label to content view
        contentView.addSubview(profileImageView)
        contentView.addSubview(messageLabel)
        
        // Set constraints
        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 30),
            profileImageView.heightAnchor.constraint(equalToConstant: 30),
            
            messageLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // Configure cell with notification data
    func configure(with notification: NotificationList) {
        
        if let image = notification.photo, let url = URL(string: image) {
            self.profileImageView.sd_setImage(with:url)
        } else {
            self.profileImageView.image = UIImage(named: kDefaultProfilePhoto)
        }
        // Create an attributed string
        let attributedString = NSMutableAttributedString()
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: ApplazAppearance.font(14, weight: .semibold)
        ]
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: ApplazAppearance.font(14)
        ]
        
        // Append the person's name in bold
        attributedString.append(NSAttributedString(string: notification.userName, attributes: boldAttributes))
        var messageString = ""
        if notification.notificationType == .like {
            messageString = " liked your note: \(notification.noteTitle)"
            } else if notification.notificationType == .comment {
                messageString = " commented on your note: \(notification.noteTitle) - \(notification.commentText ?? "")"
            }
        // Append the rest of the message in normal font
        attributedString.append(NSAttributedString(string: messageString, attributes: normalAttributes))
        
        messageLabel.attributedText = attributedString
    }
}
