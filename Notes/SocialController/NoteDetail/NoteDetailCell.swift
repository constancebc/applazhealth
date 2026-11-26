//
//  NoteDetailCell.swift
//  Notes
//
//  Created by Ghullam Abbas on 05/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SDWebImage

class NoteDetailCell: UITableViewCell {
    static let identifier = "NoteDetailCell"

    var note: NoteList? {
        didSet {
            configure()
        }
    }

    // Profile icon and username label
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let likeButton = UIButton()
    private let backgroundViewContainer = UIView()
    
    // Comments section
    private let commentsHeadingLabel = UILabel()
    private let commentsTableView = UITableView()
    
    var onLikeTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Configure profile image view
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = .gray // Placeholder color

        // Configure username label
        usernameLabel.font = ApplazAppearance.font(14, weight: .medium)
        usernameLabel.textColor = ApplazAppearance.ink

        // Configure title and description labels
        titleLabel.font = ApplazAppearance.font(16, weight: .semibold)
        descriptionLabel.font = ApplazAppearance.font(14)
        descriptionLabel.numberOfLines = 0

        // Configure buttons
        likeButton.setTitle("Like", for: .normal)
        likeButton.setTitleColor(ApplazAppearance.ink, for: .normal)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        // Configure background view
        backgroundViewContainer.layer.cornerRadius = 16
        backgroundViewContainer.layer.masksToBounds = true
        backgroundViewContainer.backgroundColor = ApplazAppearance.surface
        backgroundViewContainer.layer.borderWidth = 1
        backgroundViewContainer.layer.borderColor = ApplazAppearance.outline.cgColor

        // Comments heading
        commentsHeadingLabel.text = "Comments"
        commentsHeadingLabel.font = ApplazAppearance.font(16, weight: .semibold)
        commentsHeadingLabel.textColor = .black

        // Configure comments table view
        commentsTableView.register(CommentCell.self, forCellReuseIdentifier: "CommentCell")
        commentsTableView.dataSource = self
        commentsTableView.delegate = self
        commentsTableView.separatorStyle = .none

        // Stack for title and description
        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 8

        // Main stack view for background container
        let mainStack = UIStackView(arrangedSubviews: [stack, likeButton])
        mainStack.axis = .vertical
        mainStack.spacing = 8

        // Add subviews to the cell
        contentView.addSubview(profileImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(backgroundViewContainer)
        backgroundViewContainer.addSubview(mainStack)

        // Add comments heading and table view to contentView
        contentView.addSubview(commentsHeadingLabel)
        contentView.addSubview(commentsTableView)

        commentsTableView.estimatedRowHeight = 100 // Set an appropriate estimate
        commentsTableView.rowHeight = UITableView.automaticDimension
        
        // Constraints
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundViewContainer.translatesAutoresizingMaskIntoConstraints = false
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        commentsHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        commentsTableView.translatesAutoresizingMaskIntoConstraints = false

        // Ensure that the comments table view can expand based on its content
        NSLayoutConstraint.activate([
            // Profile image view constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),

            // Username label constraints
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            usernameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),

            // Background container constraints
            backgroundViewContainer.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            backgroundViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            backgroundViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Main stack constraints within the background container
            mainStack.topAnchor.constraint(equalTo: backgroundViewContainer.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: backgroundViewContainer.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: backgroundViewContainer.trailingAnchor, constant: -8),

            // Comments heading constraints
            commentsHeadingLabel.topAnchor.constraint(equalTo: backgroundViewContainer.bottomAnchor, constant: 8),
            commentsHeadingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            // Comments table view constraints
            commentsTableView.topAnchor.constraint(equalTo: commentsHeadingLabel.bottomAnchor, constant: 4),
            commentsTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            commentsTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentsTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            commentsTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)


    }

    private func configure() {
        guard let note = note else { return }
        titleLabel.text = note.noteTitleName
        descriptionLabel.attributedText = (note.noteDescriptionText)?.setAttributetext(fontsize: Double(descriptionLabel.font.pointSize), fontName: "HelveticaNeue-Medium")
        
        usernameLabel.text = note.nameUser

        if let image = note.photo, let url = URL(string: image) {
            self.profileImageView.sd_setImage(with: url)
        } else {
            self.profileImageView.image = UIImage(named: kDefaultProfilePhoto)
        }

        let likeTitle = note.isLiked ? "Liked: 4" : "Like"
        likeButton.setTitle(likeTitle, for: .normal)
        likeButton.setTitleColor(note.isLiked ? .gray : .blue, for: .normal)
        commentsTableView.heightAnchor.constraint(equalToConstant: CGFloat((note.comments?.count ?? 0) * 55)).isActive = true
        // Reload comments table view data
        commentsTableView.reloadData()
    }

    @objc private func likeTapped() {
        onLikeTapped?()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension NoteDetailCell: UITableViewDataSource, UITableViewDelegate {
    
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Check if the note has comments and return the count
        return note?.comments?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentCell
        cell.note = note
        cell.comment = note?.comments?[indexPath.row]
//        if let comments = note?.comments {
//            cell.textLabel?.text = comments[indexPath.row].text // Adjust based on your comment data model
//        } else {
//            cell.textLabel?.text = "No comments available" // Fallback text if no comments
//        }
        cell.textLabel?.font = ApplazAppearance.font(12)
        cell.textLabel?.textColor = .gray
        cell.selectionStyle = .none // Disable cell selection
        return cell
    }
}
