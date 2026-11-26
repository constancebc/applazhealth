//
//  NoteCell.swift
//  Notes
//
//  Created by Ghullam Abbas on 01/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

import UIKit
import Firebase

class NoteCell: UITableViewCell, UITextFieldDelegate {
    static let identifier = "NoteCell"

    var note: NoteList? {
        didSet {
            configure()
        }
    }
    
    var ref:DatabaseQuery?
    var profileKey:UInt?
    var userName: String?
    var profileUrl:String?
    
    // Profile icon and username label
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    
    private let notebookLabel = UILabel()
    private let readMoreButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let likeButton = UIButton()
    private let commentButton = UIButton()
    private let viewAllCommentsButton = UIButton()
    private let commentTextField = UITextField()
    private let backgroundViewContainer = UIView()
    private var isCommentFieldVisible = false

    var onReadMore: (() -> Void)?
    var onSaveCopy: (() -> Void)?
    var onAskAI: (() -> Void)?
    var onLikeTapped: (() -> Void)?
    var onCommentTapped: (() -> Void)?
    var onViewAllCommentsTapped: (() -> Void)?
    var onCommentSubmitted: ((String) -> Void)?
    var onProfileTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupGestureRecognizers()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        // Configure profile image view
        profileImageView.isUserInteractionEnabled = true
        profileImageView.layer.cornerRadius = 20 // Adjust based on image size
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = .gray // Placeholder color

        // Configure username label
        usernameLabel.font = ApplazAppearance.font(14, weight: .medium)
        usernameLabel.textColor = ApplazAppearance.ink
        
        // Configure title and description labels
        titleLabel.font = ApplazAppearance.font(16, weight: .semibold)
        descriptionLabel.font = ApplazAppearance.font(14)
        descriptionLabel.numberOfLines = 4
        notebookLabel.font = ApplazAppearance.font(12)
        notebookLabel.textColor = .secondaryLabel
        readMoreButton.setTitle("Read more", for: .normal)
        readMoreButton.titleLabel?.font = ApplazAppearance.font(14)
        readMoreButton.tintColor = ApplazAppearance.accent
        readMoreButton.contentHorizontalAlignment = .leading
        readMoreButton.addAction(UIAction { [weak self] _ in self?.onReadMore?() }, for: .touchUpInside)

        // Configure buttons
        likeButton.setTitle("Like", for: .normal)
        likeButton.setTitleColor(ApplazAppearance.ink, for: .normal)
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        commentButton.setTitle("Comment", for: .normal)
        commentButton.setTitleColor(ApplazAppearance.ink, for: .normal)
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)

        viewAllCommentsButton.setTitle("View All Comments", for: .normal)
        viewAllCommentsButton.setTitleColor(.gray, for: .normal)
        viewAllCommentsButton.addTarget(self, action: #selector(viewAllCommentsTapped), for: .touchUpInside)

        // Configure comment text field
        commentTextField.placeholder = "Add a comment..."
        commentTextField.borderStyle = .roundedRect
        commentTextField.isHidden = true
        commentTextField.delegate = self
        commentTextField.returnKeyType = .done

        // Set title alignment for buttons
        viewAllCommentsButton.contentHorizontalAlignment = .left // Align left
        commentButton.contentHorizontalAlignment = .right // Align right
        likeButton.contentHorizontalAlignment = .left
        
        // Configure background view
        backgroundViewContainer.layer.cornerRadius = 16
        backgroundViewContainer.layer.masksToBounds = true
        backgroundViewContainer.backgroundColor = ApplazAppearance.surface
        backgroundViewContainer.layer.borderWidth = 1
        backgroundViewContainer.layer.borderColor = ApplazAppearance.outline.cgColor

        // Stack for title and description
        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 8

        // Stack for like and comment buttons
        let buttonStack = UIStackView(arrangedSubviews: [likeButton, commentButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16

        // Main stack view for background container
        let copy = UIButton(type: .system)
        copy.setTitle("Save a copy", for: .normal)
        copy.setImage(UIImage(systemName: "bookmark"), for: .normal)
        copy.addAction(UIAction { [weak self] _ in self?.onSaveCopy?() }, for: .touchUpInside)
        let ask = UIButton(type: .system)
        ask.setTitle("Ask about this note", for: .normal)
        ask.setImage(UIImage(systemName: "sparkles"), for: .normal)
        ask.addAction(UIAction { [weak self] _ in self?.onAskAI?() }, for: .touchUpInside)
        buttonStack.addArrangedSubview(copy)
        buttonStack.distribution = .equalSpacing
        buttonStack.tintColor = ApplazAppearance.accent
        ask.tintColor = ApplazAppearance.accent
        copy.titleLabel?.font = ApplazAppearance.font(13); ask.titleLabel?.font = ApplazAppearance.font(13)
        let mainStack = UIStackView(arrangedSubviews: [stack, readMoreButton, buttonStack, viewAllCommentsButton, commentTextField, ask])
        mainStack.axis = .vertical
        mainStack.spacing = 8

        // Add subviews to the cell
        contentView.addSubview(profileImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(notebookLabel)
        notebookLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(backgroundViewContainer)
        backgroundViewContainer.addSubview(mainStack)

        // Constraints for profile image and username label
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundViewContainer.translatesAutoresizingMaskIntoConstraints = false
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Profile image view constraints
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40),

            // Username label constraints
            usernameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 8),
            usernameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor, constant: 1),
            notebookLabel.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor),
            notebookLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 3),
            notebookLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            // Background container constraints
            backgroundViewContainer.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 8),
            backgroundViewContainer.leadingAnchor.constraint(equalTo: usernameLabel.leadingAnchor, constant: 0),
            backgroundViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            backgroundViewContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Main stack constraints within the background container
            mainStack.topAnchor.constraint(equalTo: backgroundViewContainer.topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: backgroundViewContainer.leadingAnchor, constant: 8),
            mainStack.trailingAnchor.constraint(equalTo: backgroundViewContainer.trailingAnchor, constant: -8),
            mainStack.bottomAnchor.constraint(equalTo: backgroundViewContainer.bottomAnchor, constant: -8)
        ])
    }

    private func setupGestureRecognizers() {
        let profileTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
        profileImageView.addGestureRecognizer(profileTapGesture)
    }
    
    @objc private func profileTapped() {
        onProfileTapped?() // Trigger the closure for profile tap
    }
    
    private func configure() {
        guard let note = note else { return }
        titleLabel.text = note.noteTitleName
        descriptionLabel.attributedText = (note.noteDescriptionText)?.setAttributetext(fontsize: Double(descriptionLabel.font.pointSize), fontName: "AvenirNext-Regular")
        
        usernameLabel.text = note.nameUser
        notebookLabel.text = (note.parentCategoryName ?? "Notebook") + " · Public"
        readMoreButton.isHidden = (descriptionLabel.attributedText?.string.count ?? 0) < 140

        if let image = note.photo, let url = URL(string: image) {
            self.profileImageView.sd_setImage(with:url)
        } else {
            self.profileImageView.image = UIImage(named: kDefaultProfilePhoto)
        }

        viewAllCommentsButton.isHidden = note.comments?.isEmpty ?? true
        
        let likeTitle = note.likeCount > 0 ? " \(note.likeCount)" : " Like"
        likeButton.setImage(UIImage(systemName: note.isLiked ? "heart.fill" : "heart"), for: .normal)
        commentButton.setImage(UIImage(systemName: "bubble"), for: .normal)
        commentButton.setTitle(note.comments?.isEmpty == false ? " \(note.comments?.count ?? 0)" : " Comment", for: .normal)
        likeButton.accessibilityLabel = "Like note"
        commentButton.accessibilityLabel = "Comment"
        likeButton.setTitle(likeTitle, for: .normal)
        likeButton.setTitleColor(ApplazAppearance.ink.withAlphaComponent(note.isLiked ? 1 : 0.65), for: .normal)
    }

    @objc private func likeTapped() {
        onLikeTapped?()
    }

    @objc private func commentTapped() {
        isCommentFieldVisible.toggle()
        commentTextField.isHidden = !isCommentFieldVisible
        if let superview = self.superview as? UITableView {
            superview.beginUpdates()
            superview.endUpdates()
        }
        if isCommentFieldVisible {
            commentTextField.text = ""
            commentTextField.becomeFirstResponder()
        } else {
            commentTextField.resignFirstResponder()
        }
    }

    @objc private func viewAllCommentsTapped() {
        onViewAllCommentsTapped?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let commentText = textField.text, !commentText.isEmpty else { return false }
        onCommentSubmitted?(commentText)
        textField.text = ""
        textField.isHidden = true
        isCommentFieldVisible = false
        if let superview = self.superview as? UITableView {
            superview.beginUpdates()
            superview.endUpdates()
        }
        return true
    }
    
}
