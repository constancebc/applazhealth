//
//  SecondViewController.swift
//
//  Created by Bossly on 9/10/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import MessageUI

class ThumbnailCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak private var btn_Edit: UIButton!
    @IBOutlet weak private var btn_Delete: UIButton!
    @IBOutlet weak private var titleLabel: UILabel!
    
    var editButtonClouser: (() -> ())?
    var deleteButtonClouser: (() -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpButtonUI()
        imageView?.backgroundColor = ApplazAppearance.surface
        titleLabel.textColor = ApplazAppearance.ink
        titleLabel.font = ApplazAppearance.font(17, weight: .medium)
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = ApplazAppearance.outline.cgColor
        clipsToBounds = true
        btn_Edit.isHidden = true
        btn_Delete.isHidden = true
    }
    
    func configureCell(isCurrentUser: Bool, itemData: Note) {
        self.titleLabel.text = itemData.categoryName
      //  self.btn_Edit.isHidden = !isCurrentUser
        //self.btn_Delete.isHidden = !isCurrentUser
    }
    
    private func setUpButtonUI() {
        btn_Edit.addCornerRadius(radius: btn_Edit.frame.height/2)
        btn_Delete.addCornerRadius(radius: btn_Delete.frame.height/2)
        btn_Edit.tintColor = .black
        btn_Delete.tintColor = .black
    }
    
    @IBAction private func btn_EditTapped(_ sender: Any) {
        editButtonClouser?()
    }
    
    @IBAction private func btn_DeleteTapped(_ sender: Any) {
        deleteButtonClouser?()
    }
    
}

class ProfileInfoViewCell : UICollectionReusableView {
    @IBOutlet weak var lblFollowingsCount:UILabel?
    @IBOutlet weak var lblFollowersCount:UILabel?
    @IBOutlet weak var lblPostsCount:UILabel?
    
    @IBOutlet weak var pvPhoto:ProfileView?
    @IBOutlet weak var lblUsername:UILabel?
    @IBOutlet weak var btnAction:UIButton?
    @IBOutlet weak var bioText: UITextView?
    
    var defaultColor = ApplazAppearance.ink
    var currentUser:SocialUserModel?
    var otherUser: NoteList?
    
    var isFollow: Bool = false {
        didSet {
            btnAction?.layer.borderColor = defaultColor.cgColor
            
            let own = (otherUser?.user_id ?? currentUser?.ref.key) == SocialUserModel.current?.ref.key
            btnAction?.setTitle(own ? "Edit Profile" : (isFollow ? "Following ▾" : "Follow"), for: .normal)
            btnAction?.setTitleColor(.secondaryLabel, for: .normal)
            btnAction?.backgroundColor = .clear
            btnAction?.layer.borderWidth = 0
            btnAction?.showsMenuAsPrimaryAction = isFollow && !own
            btnAction?.menu = isFollow && !own ? UIMenu(children: [UIAction(title: "Unfollow", image: UIImage(systemName: "person.badge.minus")) { [weak self] _ in self?.actionButton() }]) : nil
        }
    }
    var controller:UIViewController?

    override func awakeFromNib() {
        super.awakeFromNib()
        rebuildHeaderLayout()
        backgroundColor = .clear
        lblUsername?.font = ApplazAppearance.headerFont
        lblUsername?.textColor = ApplazAppearance.ink
        for label in [lblFollowingsCount, lblFollowersCount, lblPostsCount] {
            label?.font = ApplazAppearance.font(17, weight: .medium)
            label?.textColor = ApplazAppearance.ink
        }
        bioText?.font = ApplazAppearance.font(17)
        bioText?.textColor = ApplazAppearance.ink
        bioText?.backgroundColor = .clear
        btnAction?.titleLabel?.font = ApplazAppearance.font(14, weight: .medium)
        btnAction?.setTitleColor(.secondaryLabel, for: .normal)
        btnAction?.backgroundColor = .clear
        btnAction?.layer.borderWidth = 0
        btnAction?.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        pvPhoto?.layer.borderWidth = 1
        pvPhoto?.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
    }

    private func rebuildHeaderLayout() {
        guard let photo = pvPhoto, let action = btnAction, let bio = bioText,
              let stats = lblPostsCount?.superview?.superview as? UIStackView else { return }
        let name = UILabel()
        name.numberOfLines = 2
        name.font = ApplazAppearance.headerFont
        name.textColor = ApplazAppearance.ink
        NSLayoutConstraint.deactivate(constraints)
        for child in [photo, action, bio, stats] { child.removeFromSuperview() }
        subviews.forEach { $0.removeFromSuperview() }
        NSLayoutConstraint.deactivate(photo.constraints.filter { $0.firstAttribute == .width || $0.firstAttribute == .height })
        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)), for: .normal)
        more.tintColor = ApplazAppearance.accent
        more.accessibilityLabel = "Profile options"
        more.addTarget(self, action: #selector(showProfileOptions), for: .touchUpInside)
        more.widthAnchor.constraint(equalToConstant: 44).isActive = true
        more.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let nameRow = UIStackView(arrangedSubviews: [name, more])
        nameRow.alignment = .center
        let identity = UIStackView(arrangedSubviews: [nameRow, action])
        identity.axis = .vertical
        identity.alignment = .leading
        identity.spacing = 10
        action.contentEdgeInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 8)
        action.setContentHuggingPriority(.required, for: .horizontal)
        nameRow.widthAnchor.constraint(equalTo: identity.widthAnchor).isActive = true
        action.widthAnchor.constraint(lessThanOrEqualTo: identity.widthAnchor).isActive = true
        let top = UIStackView(arrangedSubviews: [photo, identity])
        top.alignment = .center
        top.spacing = 18
        stats.distribution = .fillEqually
        stats.spacing = 8
        stats.isLayoutMarginsRelativeArrangement = true
        stats.layoutMargins = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        stats.backgroundColor = .clear
        for column in stats.arrangedSubviews.compactMap({ $0 as? UIStackView }) {
            column.spacing = 3
            if column.tag == 1 || column.tag == 2 {
                column.gestureRecognizers?.forEach { column.removeGestureRecognizer($0) }
                column.isUserInteractionEnabled = true
                column.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUsers(_:))))
            }
            for label in column.arrangedSubviews.compactMap({ $0 as? UILabel }) {
                label.font = ApplazAppearance.font(label == column.arrangedSubviews.first ? 17 : 14, weight: label == column.arrangedSubviews.first ? .medium : .regular)
                label.textColor = ApplazAppearance.ink
            }
        }
        bio.textContainerInset = .zero
        bio.textContainer.lineFragmentPadding = 0
        bio.isScrollEnabled = true
        let stack = UIStackView(arrangedSubviews: [top, stats, bio])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        lblUsername = name
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            photo.widthAnchor.constraint(equalToConstant: 72),
            photo.heightAnchor.constraint(equalToConstant: 72),
            action.heightAnchor.constraint(equalToConstant: 40),
            stats.heightAnchor.constraint(equalToConstant: 76),
            bio.heightAnchor.constraint(greaterThanOrEqualToConstant: 30)
        ])
    }

    @objc private func showUsers(_ gesture: UITapGestureRecognizer) {
        (controller as? ProfileViewController)?.showUsers(followers: gesture.view?.tag == 1)
    }

    @objc private func showProfileOptions() {
        (controller as? ProfileViewController)?.onMoreButtonClicked(self)
    }

    @IBAction func actionButton() {
        guard let viewer = SocialUserModel.current, let viewerID = viewer.ref.key,
              let targetID = otherUser?.user_id ?? currentUser?.ref.key else { return }
        if viewerID == targetID {
            controller?.performSegue(withIdentifier: "profile.edit", sender: self)
            return
        }
        let previous = isFollow
        let previousCount = lblFollowersCount?.text
        isFollow.toggle()
        let count = Int(previousCount ?? "0") ?? 0
        lblFollowersCount?.text = String(max(0, count + (isFollow ? 1 : -1)))
        btnAction?.isEnabled = false
        let value: Any = isFollow ? "true" : NSNull()
        Database.database().reference().updateChildValues([
            "\(kUsersKey)/\(viewerID)/\(kFollowinsKey)/\(targetID)": value,
            "\(kUsersKey)/\(targetID)/\(kFollowersKey)/\(viewerID)": value
        ]) { [weak self] error, _ in
            guard let self else { return }
            self.btnAction?.isEnabled = true
            if let error {
                self.isFollow = previous
                self.lblFollowersCount?.text = previousCount
                let alert = UIAlertController(title: "Couldn't update following", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.controller?.present(alert, animated: true)
            }
        }
    }

}

class ProfileViewController: UICollectionViewController {
    private let backSwipeGuard = ApplazBackSwipeGuard()

    
    @IBOutlet weak var moreBtn: UIBarButtonItem!
    var currentUser: SocialUserModel? = SocialUserModel.current
    
    // For Notes
    private var sharedObj: Shared?
    private var notes = [Note]()
    private var database = DatabaseService() //Database
    private var otherUserId: String? = nil
    var isFromSearch: Bool = false
    private var profileReference: DatabaseReference?
    private var profileObserver: DatabaseHandle?
    var actionBlockTitle = "Block profile"
    var isBlockUser = false
    var noteListObject: NoteList? = nil
    var displayedUserID: String? { noteListObject?.user_id ?? currentUser?.ref.key }
    private var blockReference: DatabaseReference?
    private var blockObserver: DatabaseHandle?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(profilePhotoUpdated(_:)), name: Notification.Name("ApplazProfilePhotoUpdated"), object: nil)
        edgesForExtendedLayout = []
        moreBtn.image = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular))
        moreBtn.tintColor = ApplazAppearance.accent
        collectionView.backgroundColor = .clear
        collectionView.backgroundView = ApplazAlignedBackdropView(frame: collectionView.bounds)
        collectionView.contentInsetAdjustmentBehavior = .always
        
        // load user profile and keep tracking update
        if let noteListObject {
            //self.getNotesAllCategories(specificUserId: noteListObject.user_id)
            self.loadActivity(noteListObject.user_id ?? "")
            self.navigationItem.title = nil
            
            
        } else {
            guard let user = self.currentUser else { return }

            // load favorites/likes collection
            if let key = user.ref.key {
                loadActivity(key)
            }
            initialSetUp()
        }


        updateNotebookSpacing()

        // remove text 'Back'
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeProfileChanges()
        if let handle = blockObserver { blockReference?.removeObserver(withHandle: handle) }
        if let viewer = SocialUserModel.current?.ref, let target = displayedUserID, target != viewer.key {
            blockReference = viewer.child("blockedUsers").child(target)
            blockObserver = blockReference?.observe(.value) { [weak self] snapshot in
                self?.isBlockUser = snapshot.exists()
                self?.collectionView.reloadData()
                self?.actionBlockTitle = snapshot.exists() ? "Unblock profile" : "Block profile"
            }
        }
        
//        self.navigationController?.navigationBar.barTintColor = .white
//        self.navigationItem.titleView?.tintColor = .white
        self.navigationController?.navigationBar.isHidden = true
        if let navigationBar = navigationController?.navigationBar {
            let appearance = navigationBar.standardAppearance.copy() as! UINavigationBarAppearance
            appearance.configureWithTransparentBackground()
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            appearance.titleTextAttributes = [.font: ApplazAppearance.headerFont, .foregroundColor: ApplazAppearance.ink]
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.shadowImage = UIImage()
        }
        DispatchQueue.main.async { [weak self] in
            self?.tabBarController?.view.setNeedsLayout()
            self?.tabBarController?.view.layoutIfNeeded()
        }
        
        if let noteListObject {
            self.navigationItem.title = nil
            
        } else {
            displayUserInfo()
        }
         // refresh username and photo
//        if let user = self.currentUser, user.isCurrent() {
//            if isFromSearch {
//                moreBtn.isEnabled = false
//                moreBtn.tintColor = .clear
//            } else {
//                moreBtn.isEnabled = true
//            }
//        }
    }
    
    @objc private func profilePhotoUpdated(_ notification: Notification) {
        if let userID = notification.object as? String,
           userID == (noteListObject?.user_id ?? currentUser?.ref.key) { collectionView.reloadData() }
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func observeProfileChanges() {
        if let handle = profileObserver { profileReference?.removeObserver(withHandle: handle) }
        guard let userID = noteListObject?.user_id ?? currentUser?.ref.key, !userID.isEmpty else { return }
        let reference = SocialUserModel.collection.child(userID)
        profileReference = reference
        profileObserver = reference.observe(.value) { [weak self] snapshot in
            guard let self else { return }
            if self.noteListObject != nil {
                self.noteListObject?.followers = (snapshot.childSnapshot(forPath: kFollowersKey).value as? [String: Any]).map { Array($0.keys) } ?? []
                self.noteListObject?.followings = (snapshot.childSnapshot(forPath: kFollowinsKey).value as? [String: Any]).map { Array($0.keys) } ?? []
                self.noteListObject?.photo = snapshot.childSnapshot(forPath: "photo").value as? String
                self.noteListObject?.nameUser = snapshot.childSnapshot(forPath: "User Name").value as? String
                self.noteListObject?.bio = snapshot.childSnapshot(forPath: "bio").value as? String
            } else if let user = self.currentUser {
                user.followersCount = snapshot.childSnapshot(forPath: kFollowersKey).childrenCount
                user.followingsCount = snapshot.childSnapshot(forPath: kFollowinsKey).childrenCount
                user.loadData(snap: snapshot) { _ in }
            }
            self.navigationItem.title = nil
            self.collectionView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        if let handle = profileObserver { profileReference?.removeObserver(withHandle: handle) }
        profileObserver = nil
        if let handle = blockObserver { blockReference?.removeObserver(withHandle: handle) }
        blockObserver = nil
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        backSwipeGuard.install(on: navigationController)
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarController?.view.setNeedsLayout()
        tabBarController?.view.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 26.0, *) {
            collectionView.topEdgeEffect.isHidden = true
        }
        updateNotebookSpacing()
    }

    private func updateNotebookSpacing() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let header = CGSize(width: collectionView.bounds.width, height: 264)
        if layout.headerReferenceSize != header { layout.headerReferenceSize = header }
        let side: CGFloat = 20
        let gap: CGFloat = 12
        guard collectionView.bounds.width > 0 else { return }
        let width = floor((collectionView.bounds.width - side * 2 - gap * 2) / 3)
        let size = CGSize(width: width, height: width)
        let insets = UIEdgeInsets(top: 16, left: side, bottom: 20, right: side)
        if layout.itemSize != size || layout.sectionInset != insets {
            layout.itemSize = size
            layout.sectionInset = insets
            layout.minimumInteritemSpacing = gap
            layout.minimumLineSpacing = gap
        }
    }

    func showUsers(followers: Bool) {
        guard let target = displayedUserID,
              let users = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileUsers") as? UsersTableViewController else { return }
        users.title = followers ? "Followers" : "Following"
        users.query = SocialUserModel.collection.child(target).child(followers ? kFollowersKey : kFollowinsKey).queryOrderedByKey()
        navigationController?.pushViewController(users, animated: true)
    }

    func displayUserInfo() {
//        let savedUserName =  UserDefaults.standard.string(forKey: "User_Name") as? String ?? self.currentUser?.name
//        self.navigationItem.title = savedUserName  /// shows the current user name here.
        
        self.navigationItem.title = nil  /// shows the current user name here.
        self.collectionView?.reloadData()
    }
    
    func loadActivity(_ userId: String) {
        
        let favorites = SocialUserModel(userId).uploads
        let ref = favorites.queryOrderedByValue()
        self.otherUserId = userId
        // bind items, and update collection 
        ref.observe(.value, with: { (snapshot) -> Void in
//            self.activities = NSMutableArray(array: snapshot.children.allObjects.reversed())
            self.getNotesAllCategories(specificUserId: self.otherUserId)
            self.collectionView?.reloadData()
        })
    }

    // MARK: - Table view data source

    // Layout views in kFavoritesColumns columns

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.activities.count
        return notes.count
    }
  
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        var profileView: ProfileInfoViewCell! = nil
        
        if kind == UICollectionView.elementKindSectionHeader {
            profileView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Cell", for: indexPath) as? ProfileInfoViewCell
            let placeholder = UIImage(named: "avatarPlaceholder")!
            if let noteListObject {
                profileView.controller = self
                
                profileView.lblFollowingsCount?.text = "\(self.noteListObject?.followings.count ?? 0)"
                profileView.lblFollowersCount?.text = "\(self.noteListObject?.followers.count ?? 0)"
                profileView.lblPostsCount?.text = "\(self.notes.count)"
                profileView.lblUsername?.text = noteListObject.nameUser
                profileView.bioText?.text = noteListObject.bio
                profileView.needsUpdateConstraints()
                profileView.otherUser = noteListObject
                profileView.currentUser = self.currentUser
                if let photo = URL(string: noteListObject.photo ?? "") {
                    profileView.pvPhoto?.sd_setImage(with: photo, placeholderImage: placeholder, completed: { (image, error, cache, url) in
                        profileView.pvPhoto?.layoutSubviews()
                    })
                }
                
                if let user = self.currentUser {
                    if let key = user.ref.key {
                        if (noteListObject.followers.contains(key)) {
                            profileView.btnAction?.setTitle("Follow", for: UIControl.State.normal)
                            profileView.btnAction?.setTitle("Unfollow", for: UIControl.State.selected)
                            profileView.isFollow = true
                        } else {
                            if (key == noteListObject.user_id) {
                                
                            } else {
                                profileView.btnAction?.setTitle("Follow", for: UIControl.State.normal)
                                profileView.btnAction?.setTitle("Unfollow", for: UIControl.State.selected)
                                profileView.isFollow = false
                            }
                            
                        }
                        
                    }
                }
                
                
            } else {
                profileView.currentUser = self.currentUser
                profileView.controller = self
                
                profileView.lblFollowingsCount?.text = "\(self.currentUser?.followingsCount ?? 0)"
                profileView.lblFollowersCount?.text = "\(self.currentUser?.followersCount ?? 0)"
                profileView.lblPostsCount?.text = "\(self.notes.count)"
                profileView.lblUsername?.text = currentUser?.getName()
                profileView.bioText?.text = currentUser?.bio
                profileView.needsUpdateConstraints()
                
                if let photo = URL(string: currentUser?.photo ?? "") {
                    profileView.pvPhoto?.sd_setImage(with: photo, placeholderImage: placeholder, completed: { (image, error, cache, url) in
                        profileView.pvPhoto?.layoutSubviews()
                    })
                }
                
                if let user = self.currentUser, !user.isCurrent() {
                    profileView.btnAction?.setTitle("Follow", for: UIControl.State.normal)
                    profileView.btnAction?.setTitle("Unfollow", for: UIControl.State.selected)
                    profileView.isFollow = user.isFollow
                }
            }
        }
        
        if let profileView {
            profileView.otherUser = noteListObject
            profileView.currentUser = currentUser
            profileView.isFollow = noteListObject.map { $0.followers.contains(SocialUserModel.current?.ref.key ?? "") } ?? currentUser?.isFollow ?? false
        }
        profileView?.btnAction?.isEnabled = !isBlockUser
        return profileView
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            as? ThumbnailCollectionViewCell else { return UICollectionViewCell() }
        
//        // Configure the cell
//        let story = Story(r.key)
//        cell.imageView?.image = UIImage(named: kDefaultProfilePhoto)
//        cell.imageView?.sd_cancelCurrentImageLoad()
//
//        story.fetchInBackground { (model, success) in
//            cell.imageView?.sd_setIndicatorStyle(.gray)
//            cell.imageView?.sd_setShowActivityIndicatorView(true)
//            cell.imageView?.sd_setImage(with: URL(string:story.media))
//        }

        cell.configureCell(isCurrentUser: self.currentUser?.isCurrent() ?? true,
                               itemData: notes[indexPath.row])
        
        cell.editButtonClouser = { [weak self] in
            self?.updateCategoryNotes(indexPath: indexPath)
        }
        
        cell.deleteButtonClouser = { [weak self] in
            alertView(nil, kDELETE_CATEGORY, ["No", "Yes"]) { (index) in
                if index == 1 {
                    self?.deleteNotesCategories(indexPath: indexPath)
                }
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let storyBoards = UIStoryboard(name:"Main", bundle: nil)
        
        let noteTitleListVC = storyBoards.instantiateViewController(withIdentifier: "NoteTitleListVC") as! NoteTitleListVC
         var userNotes = notes[indexPath.row]
        
            var notesBody:[NoteBody] = [NoteBody]()
        for each in userNotes.noteBody ?? [] {
            notesBody.append(each)
//                if let body = each.noteBody {
//                    for eachBody in body {
//                        
//                    }
//                }
            }
        if let noteListObject {
            noteTitleListVC.userId = noteListObject.user_id ?? ""
        } else {
            guard let user = self.currentUser else { return }
            if let key = user.ref.key {
                noteTitleListVC.userId = key
            }
        }
        
        noteTitleListVC.categoryTitle = userNotes.categoryName ?? "Notebook"
        noteTitleListVC.noteDictionary = ["CategoryNoteName": userNotes.categoryName ?? "Notebook", "CategoryKey": userNotes.categoryKey ?? "", "NotesBody": notesBody]
        noteTitleListVC.notesBody = notesBody
        noteTitleListVC.isFromProfile =  true
        self.navigationController?.pushViewController(noteTitleListVC, animated: true)
    }
    
    @IBAction func onMoreButtonClicked(_ sender:Any) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if displayedUserID == SocialUserModel.current?.ref.key {
            let actionLogout = UIAlertAction(title: "Invite Friends", style: .default) { (action) in
                //                self.logOut()   // As of now going back to home.
                self.openEmailForInvitaton()
            }
            actionSheet.addAction(actionLogout)
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(actionCancel)
            
            presentActionSheet(actionSheet)
        }else {
            // Send Direct Message
            let actionMessage = UIAlertAction(title: "Send a message", style: .default) { (action) in
                self.sendMessage()
            }
            actionMessage.isEnabled = !isBlockUser
            actionSheet.addAction(actionMessage)
            
            // Report the user
            let actionReport = UIAlertAction(title: "Report user", style: .destructive) { (action) in
                self.reportUser()
            }
            actionSheet.addAction(actionReport)
            let actionBlock = UIAlertAction(title: actionBlockTitle, style: .default) { [self] (action) in
                guard let viewer = SocialUserModel.current?.ref, let target = displayedUserID else { return }
                let blocked = !isBlockUser
                guard let viewerID = viewer.key else { return }
                var updates: [String: Any] = ["\(kUsersKey)/\(viewerID)/blockedUsers/\(target)": blocked ? true : NSNull()]
                if blocked {
                    updates["\(kUsersKey)/\(viewerID)/\(kFollowinsKey)/\(target)"] = NSNull()
                    updates["\(kUsersKey)/\(target)/\(kFollowersKey)/\(viewerID)"] = NSNull()
                }
                Database.database().reference().updateChildValues(updates) { [weak self] error, _ in
                    if let error {
                        let alert = UIAlertController(title: "Couldn't update block", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(alert, animated: true)
                    }
                }
            }
            actionSheet.addAction(actionBlock)
            let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            actionSheet.addAction(actionCancel)
            
            presentActionSheet(actionSheet)
        }
    }
    
    func presentActionSheet(_ actionSheet: UIAlertController) {
        if let popoverPresentationController = actionSheet.popoverPresentationController {
            popoverPresentationController.permittedArrowDirections = []
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = CGRect(
                x: view.bounds.midX,
                y: view.bounds.maxY, // Place it at the bottom of the view
                width: 0,
                height: 0
            )
            
            if let cancelButtonView = actionSheet.view.subviews.last?.subviews.first?.subviews.first {
                cancelButtonView.isHidden = false
            }
        }
        
        DispatchQueue.main.async {
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    func openEmailForInvitaton() {
        let link = "https://itunes.apple.com/us/app/whirlpost/id1450576365" // Your provided link
        
        guard MFMailComposeViewController.canSendMail() else {
            let alert = UIAlertController(title: "Cannot Send Email", message: "You haven't set up an email account on this device. Please go to Settings to add an email account.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            }))
            present(alert, animated: true, completion: nil)
            return
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        // Set the subject of the email
        mailComposer.setSubject("Check out this app!")
        
        // Construct the body of the email with the provided link
        let emailBody = "\(link)"
        mailComposer.setMessageBody(emailBody, isHTML: false)

        if UIDevice.current.userInterfaceIdiom == .pad {
            mailComposer.modalPresentationStyle = .popover
            if let popover = mailComposer.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = self.view.bounds
                popover.permittedArrowDirections = []
            }
        }
        // Present the mail composer
        present(mailComposer, animated: true, completion: nil)
    }
    
    func logOut() {
        let alert = UIAlertController(title: "Logout", message: "Do you want to log out on this device?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { (action) in
            try? Auth.auth().signOut()
            // show login page
            _ = self.tabBarController?.navigationController?.popToRootViewController(animated: true)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func backToHome() {
        Coordinator.rootViewContoller(isFirstTime: false)
    }

    func sendMessage() {
        if displayedUserID == SocialUserModel.current?.ref.key {
            self.performSegue(withIdentifier: "messages.recents", sender: nil)
        } else {
            self.performSegue(withIdentifier: "messages.direct", sender: nil)
        }
    }

    func reportUser() {
        // 1. stop listening for the notification from that user
        // -
        
        guard let key = displayedUserID else { return }
        let ReportedUser = noteListObject?.nameUser ?? currentUser?.name ?? key
        guard let ReportingUser = UserDefaults.standard.string(forKey: "User_Name") else {return}
        let body = """
        User has flagged this acount with id: \(key). Here are Details:
        Reported User: \(ReportedUser)
        Reporting User: \(ReportingUser)
        """
        print("--------------")
        print(body)
        print(self.currentUser?.name)
        print(self.currentUser?.getName())
        
        // 2. send email with report
        if (MFMailComposeViewController.canSendMail()) {
            let email = MFMailComposeViewController()
            email.setSubject("Report a user")
            email.setMessageBody(body, isHTML: false)
            email.mailComposeDelegate = self
            email.setToRecipients([kReportEmail])
            if UIDevice.current.userInterfaceIdiom == .pad {
                email.modalPresentationStyle = .popover
                if let popover = email.popoverPresentationController {
                    popover.sourceView = self.view
                    popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
            }
            
            // Present the mail composer
            present(email, animated: true, completion: nil)
        } else {
            guard MFMailComposeViewController.canSendMail() else {
                let alert = UIAlertController(title: "Cannot Send Email", message: "You haven't set up an email account on this device. Please go to Settings to add an email account.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Go to Settings", style: .default, handler: { _ in
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                }))
                present(alert, animated: true, completion: nil)
                return
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let feed = segue.destination as? StoryViewController {
            // This called when tap on cell.
//            if let indexPath = self.collectionView?.indexPathsForSelectedItems?.first,
//                let r = self.activities.object(at: (indexPath as NSIndexPath).row) as? DataSnapshot {
//                feed.storyId = r.key
//            }
        } else if let messages = segue.destination as? ChatViewController {
            // create new chat or use old one
            messages.contactRef = displayedUserID.map { SocialUserModel.collection.child($0) }
        } else if let users = segue.destination as? UsersTableViewController {
            let gesture = sender as? UITapGestureRecognizer
            let tag = gesture?.view?.tag ?? 0
            
            switch tag {
            case 1:
                users.title = "Followers"
                users.query = displayedUserID.map { SocialUserModel.collection.child($0).child(kFollowersKey).queryOrderedByKey() }
            case 2:
                users.title = "Followings"
                users.query = displayedUserID.map { SocialUserModel.collection.child($0).child(kFollowinsKey).queryOrderedByKey() }
            default: break
            }
        }
    }
}

extension ProfileViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

/// Showing the notes in profileView
extension ProfileViewController {
 
    func initialSetUp() {
        sharedObj = Shared.sharedInstance
        
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
             self.getNotesAllCategories()
        }
    }
    
}

//MARK: - Fire Base
extension ProfileViewController {

    //MARK:- GET NOTE'S ALL CATEGORIES
    func getNotesAllCategories(specificUserId: String? = nil) {
        database.getData(specificUserId: specificUserId) { (arrayOfNotes) in
            DispatchQueue.main.async {
                self.notes = arrayOfNotes.filter { !($0.isPrivateNote ?? false) }
                self.collectionView.reloadData()
            }
        }
    }
    
    //MARK:- DELETE NOTE'S CATEGORIES
    func deleteNotesCategories(indexPath: IndexPath) {
        if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
            let note = notes[indexPath.row]
            database.deleteFromDatabase(category: note.categoryKey, title: nil)
            self.getNotesAllCategories()
        } else {
            notes.remove(at: indexPath.row)
            self.collectionView.reloadData()
        }
    }
    
    func updateCategoryNotes(indexPath: IndexPath) {
        var note = self.notes[indexPath.row]
        
        let alertController = UIAlertController(title: "Notebook", message: "Update Notebook", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Update", style: .default) { (_) in
            if let field = alertController.textFields![0] as? UITextField {
                if field.text?.removeNull() != "" {
                    
                    if !(UserDefaults.standard.bool(forKey: Guest_Key)) {
                        self.database.editDatabaseRecords(categoryNote: field.text!.removeNull(), titleNote: nil, categoryKey: note.categoryKey, titleKey: nil, note: nil, isPrivateNote: nil){ (err) in
                            if let _ = err {
                                // Toast(text: "\(kCATEGORY_NOT_UPDATED)").show()
                            } else {
                                // Toast(text: "\(kCATEGORY_UPDATED)").show()
                            }
                        }
                        self.getNotesAllCategories()
                    } else {
                        note.categoryName = field.text!.removeNull()
                        self.notes.remove(at: indexPath.row)
                        self.notes.append(note)
                        self.collectionView.reloadData()
                    }
                    
                } else {
                    // Toast(text: kENTER_NOTE_CATEGORY).show()
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.text = note.categoryName!
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
}
