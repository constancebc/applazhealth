//
//  CommentCell.swift
//  Notes
//
//  Created by Ghullam Abbas on 05/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

class CommentCell: UITableViewCell {
    static let identifier = "CommentCell"

    // Comment model
    var comment: NoteComment? {
        didSet {
            configure()
        }
    }
    var note: NoteList?
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let commentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Configure the profile image view
        profileImageView.layer.cornerRadius = 15
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = .gray // Placeholder color

        // Configure the username label
        usernameLabel.font = ApplazAppearance.font(14, weight: .semibold)
        usernameLabel.textColor = .black

        // Configure the comment label
        commentLabel.numberOfLines = 0
        commentLabel.font = ApplazAppearance.font(14)
        commentLabel.textColor = .gray

        // Add subviews to the content view
        contentView.addSubview(profileImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(commentLabel)

        // Set up constraints
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        commentLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Profile image view constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.widthAnchor.constraint(equalToConstant: 30),
            profileImageView.heightAnchor.constraint(equalToConstant: 30),

            // Username label constraints
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Comment label constraints
            commentLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor, constant: 0),
            commentLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            commentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            commentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    private func configure() {
        commentLabel.text = comment?.commentText // Assuming `text` is a property of your Comment model
        usernameLabel.text = comment?.userName
        if let image = comment?.userProfilePicture, let url = URL(string: image) {
            self.profileImageView.sd_setImage(with:url)
        } else {
            self.profileImageView.image = UIImage(named: kDefaultProfilePhoto)
        }
    }
}
