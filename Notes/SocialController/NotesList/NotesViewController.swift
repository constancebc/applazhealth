//
//  NoteListVC.swift
//  Notes
//
//  Created by Ghullam Abbas on 01/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import GoogleMobileAds
import Firebase

class NotesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CommentViewControllerDelegate {
    

    @IBOutlet weak var followingMenu: UIBarButtonItem!
    @IBOutlet weak var whirldMenu: UIBarButtonItem!
    @IBOutlet weak var notificationIcon: UIBarButtonItem!
    var badgeLabel: UILabel?
    
    private let tableView = UITableView()
    private var mainDataArray: [NoteList] = []
    private var database = DatabaseService()
    private var noteListArray = [NoteList]()
    private var followingListArray = [NoteList]()
    var currentUser: SocialUserModel? = SocialUserModel.current
   
    var currentFeed: FeedType = .whirld
    var badgeCount = 0
    private var friendsQuery: DatabaseQuery?
    private var friendsHandle: DatabaseHandle?
    private var friendsGeneration = UUID()
    private var blockedIDs = Set<String>()
    private var blockedReference: DatabaseReference?
    private var blockedHandle: DatabaseHandle?
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let friendsHandle { friendsQuery?.removeObserver(withHandle: friendsHandle) }
        if let blockedHandle { blockedReference?.removeObserver(withHandle: blockedHandle) }
    }

    
    
    // Admob variables
      var adiPath = 2 // Nth item for ads
      var adReq = 0
      var adToShow = 0 // Nuber of ads to show
      var adRetCnt = 0 // Number of items returned

      /// The native ads.
      var nativeAds = [GADNativeAd]()

      /// The ad loader that loads the native ads.
      var adLoader: GADAdLoader!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = [.top, .bottom]
        let backdrop = ApplazAlignedBackdropView(frame: view.bounds)
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(backdrop, at: 0)
        NSLayoutConstraint.activate([
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let symbolStyle = UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)
        followingMenu.image = ApplazAppearance.socialIcon
        followingMenu.tintColor = ApplazAppearance.accent
        followingMenu.accessibilityLabel = "Friends"
        whirldMenu.image = UIImage(systemName: "sparkles", withConfiguration: symbolStyle)
        whirldMenu.accessibilityLabel = "For You"
        notificationIcon.image = UIImage(systemName: "heart", withConfiguration: symbolStyle)
        notificationIcon.accessibilityLabel = "Notifications"
        navigationItem.leftBarButtonItems?.first?.image = UIImage(systemName: "book.closed", withConfiguration: symbolStyle)
        navigationItem.leftBarButtonItems?.first?.accessibilityLabel = "Notebooks"
        blockedReference = SocialUserModel.current?.ref.child("blockedUsers")
        blockedHandle = blockedReference?.observe(.value) { [weak self] snapshot in
            guard let self else { return }
            self.blockedIDs = Set((snapshot.value as? [String: Any] ?? [:]).keys)
            self.applySelectedFeed()
        }
        setupTableView()
        applySelectedFeed()
        getNotesList()
        getNotesAllFollowing()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshActivityBadge), name: ApplazActivityInbox.changed, object: nil)
        ApplazActivityInbox.shared.start()
        refreshActivityBadge()
        self.navigationController?.title = "Notes"

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ApplazActivityInbox.shared.start()
        refreshActivityBadge()
        self.navigationController?.navigationBar.isHidden = false
        // Create a new UINavigationBarAppearance instance
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            
            // Set the background color (optional)
            appearance.backgroundColor = .clear
            
            // Set the separator (shadow) color
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage() // Ensures a solid separator line
            // Set the tint color for bar button items
            appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: ApplazAppearance.ink, .font: ApplazAppearance.font(16, weight: .medium)]
            appearance.buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: ApplazAppearance.ink]
            // Apply appearance to navigation bar
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            
            navigationController?.navigationBar.tintColor = ApplazAppearance.accent

        } else {
            
        }
        
        self.navigationController?.navigationBar.isHidden = false
        
    }
    
    @objc private func refreshActivityBadge() {
        showBadge(on: notificationIcon, badgeCount: ApplazActivityInbox.shared.unread)
    }

    func showBadge(on barButtonItem: UIBarButtonItem, badgeCount: Int) {
        // Remove any existing badge if it exists
        badgeLabel?.removeFromSuperview()
        
        // Create the badge label
        badgeLabel = UILabel()
        badgeLabel?.text = badgeCount > 99 ? "99+" : "\(badgeCount)"
        badgeLabel?.isHidden = badgeCount == 0
        badgeLabel?.textAlignment = .center
        badgeLabel?.font = ApplazAppearance.font(10, weight: .medium)
        badgeLabel?.textColor = .white
        badgeLabel?.backgroundColor = UIColor(red: 0.83, green: 0.25, blue: 0.30, alpha: 1)
        badgeLabel?.layer.backgroundColor = UIColor(red: 0.83, green: 0.25, blue: 0.30, alpha: 1).cgColor
        badgeLabel?.layer.cornerRadius = 8
        badgeLabel?.layer.masksToBounds = true
        badgeLabel?.frame = CGRect(x: 18, y: -4, width: 16, height: 16)
        
        // Create a custom view for the UIBarButtonItem
        let barButtonView = UIView()
        barButtonView.isUserInteractionEnabled = true
        let buttonImageView = UIImageView(image: barButtonItem.image) // Use the image from the original bar button item
        buttonImageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Adjust size to match the icon
        buttonImageView.contentMode = .center
        buttonImageView.tintColor = ApplazAppearance.accent
        
        // Add the image and badge to the custom view
        barButtonView.addSubview(buttonImageView)
        barButtonView.addSubview(badgeLabel!)
        barButtonView.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Size of the custom view
        
        // Set the custom view as the bar button item
        barButtonItem.customView = barButtonView
        barButtonView.accessibilityLabel = "Notifications"
        barButtonView.accessibilityValue = "\(badgeCount) unread"
        if #available(iOS 26.0, *) { barButtonItem.hidesSharedBackground = true }
        
        // Add gesture recognizer for the custom view to handle the action
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(notificationIconTapped))
        barButtonView.addGestureRecognizer(tapGesture)
        
    }

    

    @objc func notificationIconTapped() {
        self.notificationclicked(self)
    }

    func hideBadge(on barButtonItem: UIBarButtonItem) {
        // Remove badge if it exists
        badgeLabel?.removeFromSuperview()
        barButtonItem.customView = nil
    }
    func didSelectComment(note: NoteList) {
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        let vc = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        vc.noteListObject = note
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func getNotesList() {
        database.getAllUser { [weak self] allUsers in
            DispatchQueue.main.async {
                guard let self else { return }
                self.mainDataArray = []
                self.applySelectedFeed()
                for userID in allUsers {
                    self.database.getNoteListData(specificUserId: userID) { [weak self] notes in
                        DispatchQueue.main.async {
                            guard let self else { return }
                            self.receivePublicNotes(notes, from: userID)
                        }
                    }
                }
            }
        }
    }

    func getNotesAllFollowing() {
        if let friendsHandle { friendsQuery?.removeObserver(withHandle: friendsHandle) }
        guard let query = SocialUserModel.current?.followings.queryOrderedByKey() else { return }
        friendsQuery = query
        friendsHandle = query.observe(.value) { [weak self] snapshot in
            DispatchQueue.main.async {
                guard let self else { return }
                let generation = UUID()
                self.friendsGeneration = generation
                self.followingListArray = []
                self.applySelectedFeed()
                for case let child as DataSnapshot in snapshot.children {
                    self.database.getNoteListData(specificUserId: child.key) { [weak self] notes in
                        DispatchQueue.main.async {
                            guard let self, self.friendsGeneration == generation else { return }
                            self.receiveFriendsNotes(notes, from: child.key)
                        }
                    }
                }
            }
        }
    }

    func receivePublicNotes(_ notes: [NoteList], from userID: String) {
        mainDataArray.removeAll { $0.user_id == userID }
        mainDataArray.append(contentsOf: notes.filter { $0.isPrivateNote == false })
        applySelectedFeed()
    }

    func receiveFriendsNotes(_ notes: [NoteList], from userID: String) {
        followingListArray.removeAll { $0.user_id == userID }
        followingListArray.append(contentsOf: notes.filter { $0.isPrivateNote == false })
        applySelectedFeed()
    }

    private func applySelectedFeed() {
        noteListArray = (currentFeed == .following ? followingListArray : mainDataArray).filter { !blockedIDs.contains($0.user_id ?? "") }
        tableView.reloadData()
        followingMenu.image = UIImage(systemName: currentFeed == .following ? "person.2.fill" : "person.2", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .regular))
        followingMenu.tintColor = ApplazAppearance.accent
        whirldMenu.tintColor = currentFeed == .whirld ? ApplazAppearance.ink : ApplazAppearance.ink.withAlphaComponent(0.45)
        followingMenu.accessibilityValue = currentFeed == .following ? "Selected" : "Not selected"
        whirldMenu.accessibilityValue = currentFeed == .whirld ? "Selected" : "Not selected"
        let title = UILabel()
        title.font = ApplazAppearance.headerFont
        title.textColor = ApplazAppearance.ink
        title.text = currentFeed == .following ? "Friends" : "Newsfeed"
        navigationItem.titleView = title
        let empty = UILabel()
        empty.text = currentFeed == .following ? "Notes from people you follow appear here." : "Public notes will appear here."
        empty.font = ApplazAppearance.font(17)
        empty.textColor = ApplazAppearance.ink
        empty.numberOfLines = 0
        empty.textAlignment = .center
        tableView.backgroundView = noteListArray.isEmpty ? empty : ApplazAlignedBackdropView(frame: tableView.bounds)
    }

    private func setupTableView() {
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(NoteCell.self, forCellReuseIdentifier: NoteCell.identifier)
        view.addSubview(tableView)
        
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.backgroundView = ApplazAlignedBackdropView(frame: tableView.bounds)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 2),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    // TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         
            return noteListArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteCell.identifier, for: indexPath) as? NoteCell else {
            return UITableViewCell()
        }
        

        let noteObject = noteListArray[indexPath.row]
                
        cell.note = noteObject
        cell.onReadMore = { [weak self] in
            let detail = NoteDetailViewController(); detail.note = noteObject
            self?.navigationController?.pushViewController(detail, animated: true)
        }
        cell.onAskAI = { [weak self] in
            guard let self else { return }
            WellnessPresentation.publicNoteChat(noteObject, from: self)
        }
        cell.onSaveCopy = { [weak self] in
            guard WellnessStore.shared.savePublicCopy(noteObject) else { return }
            let alert = UIAlertController(title: "Saved privately", message: "Find this copy in your private Saved notes notebook.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default)); self?.present(alert, animated: true)
        }
        cell.onProfileTapped = {
            self.navigateToProfile(note: noteObject)
        }
        
        cell.onLikeTapped = { [weak self] in
            guard let self else { return }
            let status = !noteObject.isLiked
            self.database.updateNoteWithLikeStatus(user_id: noteObject.user_id ?? "", categoryKey: noteObject.parentCategoryKey, noteKey: noteObject.noteKey, isLiked: status) { [weak self] count, error in
                guard let self, error == nil, let count else { return }
                DispatchQueue.main.async {
                    func updated(_ notes: [NoteList]) -> [NoteList] {
                        notes.map { value in
                            var value = value
                            if value.user_id == noteObject.user_id && value.parentCategoryKey == noteObject.parentCategoryKey && value.noteKey == noteObject.noteKey {
                                value.isLiked = status; value.likeCount = count
                            }
                            return value
                        }
                    }
                    self.mainDataArray = updated(self.mainDataArray)
                    self.followingListArray = updated(self.followingListArray)
                    self.applySelectedFeed()
                }
            }
        }

        cell.onCommentTapped = {
            self.showCommentInput(for: noteObject)
        }
        
        cell.onCommentSubmitted = { [weak self] commentText in
            self?.addOrUpdateComment(note: noteObject, newCommentText: commentText)
        }
        cell.onViewAllCommentsTapped = {
            self.showCommentsBottomSheet(for: noteObject)
        }
        
            
        return cell
    }
    
    func filterNotes(byLikedUserID noteObject: NoteList, from noteListArray: [NoteList]) -> [NoteList] {
        // Create an empty array to store notes with the liked user IDs
        var likesArray = [NoteList]()
        
        // Loop through all the user IDs in the noteObject's 'likes' array
        for (id, _) in noteObject.likes {
            // Find the first note in the noteListArray where the user_id matches the liked user ID
            if let note = noteListArray.first(where: { $0.user_id == id }) {
                // If the note exists, add it to the likesArray
                likesArray.append(note)
            }
        }
        
        return likesArray
    }

    
    func mapLikesToNotifications(likesArray: [NoteList]) -> [NotificationList] {
        var notifications = [NotificationList]()

        for note in likesArray {
            // Ensure that we have a valid user_id in the note object to be used in the notification
            guard let userID = note.user_id else {
                continue // If there's no user_id, skip this note
            }
            
            // Create a notification for the like
            let likeNotification = NotificationList(
                photo: note.photo,
                userID: userID,  // Now the userID is fetched directly from the note
                userName: note.nameUser ?? "",
                noteKey: note.noteKey ?? "",
                noteTitle: note.noteTitleName ?? "",
                notificationType: .like,
                commentText: nil, // No comment text needed for a like notification
                timestamp: Date().timeIntervalSince1970,
                parentCategoryName: note.parentCategoryName,
                parentCategoryKey: note.parentCategoryKey,
                isPrivateNote: note.isPrivateNote,
                noteDescriptionText: note.noteDescriptionText,
                isLiked: note.isLiked,
                comments: note.comments,
                followings: note.followings,
                followers: note.followers,
                bio: note.bio,
                likeCount: note.likeCount
            )
            
            notifications.append(likeNotification)
        }

        return notifications
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let note = noteListArray[indexPath.row]
        let noteDetailVC = NoteDetailViewController()
        noteDetailVC.note = note
        //noteDetailVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(noteDetailVC, animated: true)
    }
    
    func isValidCategoryKey(_ key: String) -> Bool {
        // Define a regular expression that matches any forbidden character
        let forbiddenCharactersPattern = "[.#$\\[\\]]"
        
        // Check if the key contains any forbidden character
        if let _ = key.range(of: forbiddenCharactersPattern, options: .regularExpression) {
            return false // Invalid key, contains forbidden characters
        }
        return true // Valid key, no forbidden characters
    }
    
    func addOrUpdateComment(note: NoteList, newCommentText: String, commentID: String? = nil) {
        
            // Create a new comment with user details and current timestamp
        guard let user = self.currentUser else { return }
        guard let key = user.ref.key else  { return }
            let newComment = NoteComment(
                userID: key,
                userName: user.getName(), // Assuming `displayName` is set
                userProfilePicture: user.photo,
                commentText: newCommentText,
                timestamp: Date().timeIntervalSince1970
            )

            // Call the `updateNoteWithComment` function
        self.database.updateNoteWithComment(
            commenting_user_id: note.user_id, categoryKey: note.parentCategoryKey,
            noteKey: note.noteKey,
                newComment: newComment
            )
    }

    private func showCommentInput(for note: NoteList) {
        // Present comment input view or handle comment input
    }
    
    private func showCommentsBottomSheet(for note: NoteList) {
        let commentsVC = CommentsViewController(comments: note.comments ?? [], note: note)
        commentsVC.delegate = self
        commentsVC.modalPresentationStyle = .pageSheet
        if let sheet = commentsVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        self.present(commentsVC, animated: true, completion: nil)
        
    }
    
    @IBAction func notificationclicked(_ sender: Any) {
        ApplazActivityInbox.shared.markRead()
        let vc = NotificationViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func whirldMenuClicked(_ sender: Any) {
        currentFeed = .whirld
        applySelectedFeed()
    }
    
    @IBAction func followingMenuClicked(_ sender: Any) {
        currentFeed = .following
        applySelectedFeed()
    }
    
    @IBAction func noteBookMenu(_ sender: Any) {
        if let dashboard = tabBarController as? DashboardController {
            dashboard.showNotebooks()
        }

    }
    
    private func navigateToProfile(note: NoteList) {
        let storyBoard = UIStoryboard(name: "Profile", bundle: nil)
        
        let vc = storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        vc.noteListObject = note
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}
 

//extension NotesViewController: GADNativeAdLoaderDelegate, GADNativeAdDelegate  {
//    
//  func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
//     print("Failed to receive ads")
//      print(error.localizedDescription)
//  }
//
//  func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
//     // A native ad has loaded, and can be displayed.
//     self.nativeAds.append(nativeAd)
//  }
// 
//    func adLoaderDidFinishLoading(_ adLoader: GADAdLoader) {
//        
//        // The adLoader has finished loading ads, and a new request can be sent.
//        print("ad did finish loading.....")
//        let adInterval = 10 // Display ad every 10 items
//        let adRepeatLimit = 10 // Repeat ad display 10 times
//        
//        let numberOfNotes = notes.count
//        
//        var adRepeatCount = 0
//        var adPosition = 2 // Start displaying ad after the second notebook
//        
//        while adRepeatCount < adRepeatLimit && adPosition < numberOfNotes {
//            if let nativeAd = self.nativeAds.first {
//                self.notes.insert(nativeAd, at: adPosition)
//                print("Native ad inserted at:\(adPosition)")
//                adPosition += adInterval + 1 // Move to the next ad position
//                adRepeatCount += 1
//            }else{
//                print("Ad did not loaded..")
//                break
//            }
//        }
//       // self.collectionView.reloadData()
//    }
//
//// This for debugging
//func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
//   print("The native ad was shown.")
//}
//
//func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
//    print("The native ad was clicked on.")
//}
//
//func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
//    print("The native ad will present a full screen view.")
//}
//
//func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
//   print("The native ad will dismiss a full screen view.")
//}
//
//func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
//   print("The native ad did dismiss a full screen view.")
//}
//
//func nativeAdWillLeaveApplication(_ nativeAd: GADNativeAd) {
//   print("The native ad will cause the application to become inactive and open a new application.")
// }
//}
