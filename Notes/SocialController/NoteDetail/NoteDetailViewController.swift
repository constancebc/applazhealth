import UIKit
import FirebaseDatabase
import FirebaseAuth
import SDWebImage

class NoteDetailViewController: UIViewController {
    var note: NoteList?
    var noteKey: String?
    var userId: String?
    private var database = DatabaseService()
    private var noteReference: DatabaseReference?
    private var noteObserver: DatabaseHandle?
    private let scrollView = UIScrollView()
    private let content = UIStackView()
    private let profileImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let likeButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let copyButton = UIButton(type: .system)
    private let askButton = UIButton(type: .system)
    private var inlineAI: AIInlinePanelController?
    private var inlineAIHeight: NSLayoutConstraint?
    private let commentRows = UIStackView()
    private let commentField = UITextField()
    private let sendButton = UIButton(type: .system)

    override func loadView() { view = ApplazSurfaceView(frame: .zero) }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Note Details"
        setupViews()
        configure()
        if let userId, let noteKey { getNoteDetail(user_id: userId, noteKey: noteKey) }
        else { configure(); observeNote() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        observeNote()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let handle = noteObserver { noteReference?.removeObserver(withHandle: handle) }
        noteObserver = nil
    }

    private func setupViews() {
        let composer = UIStackView(arrangedSubviews: [commentField, sendButton])
        composer.spacing = 8
        composer.backgroundColor = ApplazAppearance.surface
        composer.layer.cornerRadius = 14
        composer.isLayoutMarginsRelativeArrangement = true
        composer.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 8)
        commentField.placeholder = "Write a comment…"
        commentField.font = ApplazAppearance.font(16)
        commentField.textColor = ApplazAppearance.ink
        commentField.addTarget(self, action: #selector(updateSendButton), for: .editingChanged)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .regular)), for: .normal)
        sendButton.accessibilityLabel = "Send comment"
        sendButton.tintColor = ApplazAppearance.accent
        sendButton.isEnabled = false
        sendButton.addTarget(self, action: #selector(sendComment), for: .touchUpInside)
        view.addSubview(scrollView)
        view.addSubview(composer)
        scrollView.keyboardDismissMode = .interactive
        scrollView.addSubview(content)
        content.axis = .vertical
        content.spacing = 16
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 22
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
        usernameLabel.font = ApplazAppearance.font(17, weight: .medium)
        usernameLabel.textColor = ApplazAppearance.ink
        let profileRow = UIStackView(arrangedSubviews: [profileImageView, usernameLabel])
        profileRow.spacing = 12
        profileRow.alignment = .center
        content.addArrangedSubview(profileRow)
        titleLabel.font = ApplazAppearance.font(22, weight: .medium)
        titleLabel.textColor = ApplazAppearance.ink
        titleLabel.numberOfLines = 0
        descriptionLabel.font = ApplazAppearance.font(17)
        descriptionLabel.textColor = ApplazAppearance.ink
        descriptionLabel.numberOfLines = 0
        content.addArrangedSubview(titleLabel)
        content.addArrangedSubview(descriptionLabel)
        for button in [likeButton, commentButton] {
            button.tintColor = ApplazAppearance.accent
            button.titleLabel?.font = ApplazAppearance.font(16, weight: .medium)
            button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)
        commentButton.setTitle("Comment", for: .normal)
        commentButton.addTarget(self, action: #selector(focusComment), for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [likeButton, commentButton])
        actions.distribution = .fillEqually
        actions.spacing = 16
        content.addArrangedSubview(actions)
        for (button, title, icon) in [(copyButton, "Save a copy", "bookmark"), (askButton, "Ask about this note", "sparkle")] {
            var configuration = UIButton.Configuration.bordered()
            configuration.title = title; configuration.image = UIImage(systemName: icon); configuration.imagePadding = 6
            configuration.baseForegroundColor = ApplazAppearance.accent; configuration.baseBackgroundColor = ApplazAppearance.surface
            configuration.cornerStyle = .capsule
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in var result = attributes; result.font = ApplazAppearance.font(14); return result }
            configuration.titleLineBreakMode = .byWordWrapping
            button.configuration = configuration; button.titleLabel?.numberOfLines = 2
            button.accessibilityLabel = title
        }
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        askButton.addTarget(self, action: #selector(askTapped), for: .touchUpInside)
        let notebookActions = UIStackView(arrangedSubviews: [copyButton, askButton]); notebookActions.spacing = 10; notebookActions.distribution = .fillEqually
        content.addArrangedSubview(notebookActions)
        let heading = UILabel()
        heading.text = "Comments"
        heading.font = ApplazAppearance.font(18, weight: .medium)
        heading.textColor = ApplazAppearance.ink
        content.addArrangedSubview(heading)
        commentRows.axis = .vertical
        commentRows.spacing = 16
        content.addArrangedSubview(commentRows)
        for element in [scrollView, composer, content, profileImageView] { element.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            composer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            composer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            composer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8),
            composer.heightAnchor.constraint(equalToConstant: 52),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -8),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            profileImageView.widthAnchor.constraint(equalToConstant: 44),
            profileImageView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func getNoteDetail(user_id: String, noteKey: String) {
        database.getSpecificNoteData(specificUserId: user_id, specificNoteId: noteKey) { [weak self] note in
            DispatchQueue.main.async {
                guard let note else { return }
                self?.note = note; self?.configure(); self?.observeNote()
            }
        }
    }

    private func observeNote() {
        guard noteObserver == nil, let note, let owner = note.user_id, let category = note.parentCategoryKey, let key = note.noteKey else { return }
        let reference = Database.database().reference().child("Users").child(owner).child("Notes").child(category).child(key)
        noteReference = reference
        noteObserver = reference.observe(.value) { [weak self] snapshot in
            guard let self, snapshot.exists() else { return }
            let likes = snapshot.childSnapshot(forPath: "likes").value as? [String: Bool] ?? [:]
            self.note?.likes = likes
            self.note?.isLiked = Auth.auth().currentUser.map { likes[$0.uid] == true } ?? false
            self.note?.likeCount = snapshot.childSnapshot(forPath: "likeCount").value as? Int ?? snapshot.childSnapshot(forPath: "likesCount").value as? Int ?? 0
            self.note?.comments = (snapshot.childSnapshot(forPath: "comments").value as? [[String: Any]] ?? []).compactMap { item in
                guard let userID = item["userID"] as? String, let text = item["commentText"] as? String else { return nil }
                return NoteComment(userID: userID, userName: item["userName"] as? String ?? "", userProfilePicture: item["userProfilePicture"] as? String ?? "", commentText: text, timestamp: item["timestamp"] as? Double ?? 0)
            }
            self.configure()
        }
    }

    private func configure() {
        guard isViewLoaded, let note else { return }
        copyButton.isHidden = note.isPrivateNote != false
        let scope = WellnessPresentation.noteChatScope(note)
        askButton.isHidden = scope == nil
        let owner = Auth.auth().currentUser?.uid ?? SocialUserModel.current?.ref.key
        if owner != nil, note.user_id == owner, scope != nil, inlineAI == nil {
            let panel = AIInlinePanelController(title: "Ask about this note", scope: { [weak self] in
                guard let note = self?.note else { return .note("") }
                return WellnessPresentation.noteChatScope(note) ?? .note("")
            })
            inlineAI = panel
            addChild(panel); panel.loadViewIfNeeded()
            content.insertArrangedSubview(panel.view, at: 3)
            let height = panel.view.heightAnchor.constraint(equalToConstant: 240)
            inlineAIHeight = height; height.isActive = true
            panel.heightChanged = { [weak self] value in self?.inlineAIHeight?.constant = value }
            panel.didMove(toParent: self)
        }
        usernameLabel.text = note.nameUser
        titleLabel.text = note.noteTitleName
        descriptionLabel.attributedText = note.noteDescriptionText?.setAttributetext(fontsize: 17, fontName: "AvenirNext-Regular")
        profileImageView.sd_setImage(with: URL(string: note.photo ?? ""), placeholderImage: UIImage(named: kDefaultProfilePhoto))
        likeButton.setTitle("  \(note.isLiked ? "Liked" : "Like") · \(note.likeCount)", for: .normal)
        likeButton.setImage(UIImage(systemName: note.isLiked ? "heart.fill" : "heart"), for: .normal)
        commentRows.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for comment in note.comments ?? [] {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = ApplazAppearance.font(16)
            label.textColor = ApplazAppearance.ink
            label.text = "\(comment.userName)\n\(comment.commentText)"
            commentRows.addArrangedSubview(label)
        }
    }

    @objc private func copyTapped() {
        guard let note, WellnessStore.shared.savePublicCopy(note) else { return }
        let alert = UIAlertController(title: "Saved privately", message: "Find this copy in your private Saved notes notebook.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
    }
    @objc private func askTapped() { guard let note else { return }; WellnessPresentation.publicNoteChat(note, from: self) }
    @objc private func likeTapped() {
        guard let note, let owner = note.user_id else { return }
        likeButton.isEnabled = false
        database.updateNoteWithLikeStatus(user_id: owner, categoryKey: note.parentCategoryKey, noteKey: note.noteKey, isLiked: !note.isLiked) { [weak self] count, error in
            guard let self else { return }
            self.likeButton.isEnabled = true
            if let error { self.showError(error) }
            else { self.note?.isLiked = !note.isLiked; self.note?.likeCount = count ?? note.likeCount; self.configure() }
        }
    }

    @objc private func focusComment() { commentField.becomeFirstResponder() }
    @objc private func updateSendButton() { sendButton.isEnabled = !(commentField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    @objc private func sendComment() {
        guard let note, let user = SocialUserModel.current, let key = user.ref.key else { return }
        let text = (commentField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        sendButton.isEnabled = false
        let comment = NoteComment(userID: key, userName: user.getName(), userProfilePicture: user.photo, commentText: text, timestamp: Date().timeIntervalSince1970)
        database.updateNoteWithComment(commenting_user_id: note.user_id, categoryKey: note.parentCategoryKey, noteKey: note.noteKey, newComment: comment) { [weak self] error in
            guard let self else { return }
            if let error { self.showError(error) }
            else { self.commentField.text = ""; self.commentField.resignFirstResponder() }
            self.updateSendButton()
        }
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Couldn't save", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func profileTapped() {
        guard let note else { return }
        let profile = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        profile.noteListObject = note
        navigationController?.pushViewController(profile, animated: true)
    }
}
