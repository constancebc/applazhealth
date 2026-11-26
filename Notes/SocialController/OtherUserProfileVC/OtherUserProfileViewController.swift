//
//  OtherUserProfileViewController.swift
//  Notes
//
//  Created by Ghullam Abbas on 05/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

import UIKit

class OtherUserProfileViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50 // Adjust the radius as per the image size
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray // Placeholder color
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = ApplazAppearance.font(20, weight: .bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = ApplazAppearance.font(14, weight: .regular)
        label.textColor = .darkGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let followersLabel: UILabel = {
        let label = UILabel()
        label.font = ApplazAppearance.font(16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let followingLabel: UILabel = {
        let label = UILabel()
        label.font = ApplazAppearance.font(16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let followInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()
    
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()
    
    var note: NoteList?
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Profile"
        view.backgroundColor = ApplazAppearance.canvas
        setupViews()
        setupConstraints()
        configureData()
    }
    
    // MARK: - Setup Views and Constraints
    
    private func setupViews() {
        // Add subviews to the stack views
        followInfoStackView.addArrangedSubview(followersLabel)
        followInfoStackView.addArrangedSubview(followingLabel)
        
        mainStackView.addArrangedSubview(profileImageView)
        mainStackView.addArrangedSubview(usernameLabel)
        mainStackView.addArrangedSubview(bioLabel)
        mainStackView.addArrangedSubview(followInfoStackView)
        
        // Add the main stack view to the main view
        view.addSubview(mainStackView)
    }
    
    private func setupConstraints() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Profile Image View size constraints
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            // Center the main stack view
            mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Limit the bio label's width for better readability on larger screens
            bioLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])
    }
    
    // MARK: - Data Configuration
    
    private func configureData() {
        // Sample data for testing purposes
        if let user = note {
            if let image = note?.photo, let url = URL(string: image) {
                self.profileImageView.sd_setImage(with: url)
            } else {
                self.profileImageView.image = UIImage(named: kDefaultProfilePhoto)
            }
             // Replace with actual image URL
            usernameLabel.text = user.nameUser
            bioLabel.text = user.bio
            
            // Set followers and following information
            followersLabel.text = "Followers: \(user.followers.count)"
            followingLabel.text = "Following: \(user.followings.count)"
        }
    }
}
