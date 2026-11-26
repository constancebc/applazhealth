//
//  FirstViewController.swift
//
//  Created by Bossly on 9/10/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import SDWebImage
import AVFoundation
import DateToolsSwift
import MessageUI

class FeedViewController: UITableViewController, StoryTableViewCellDelegate {

    @IBOutlet var emptyView: UIView?
    
//    var posts:[DataSnapshot] = []
//    var lastKey:DataSnapshot?
//    var stopPaginationLoading:Bool = false
//    var collection = Story.recents

//    var newRef:DatabaseQuery?
//    var oldRef:DatabaseQuery?
//    var activeCell: StoryTableViewCell? // cell in center

    // used to show only one story
    var singleStoryId:String?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View cycle

    override func viewDidLoad() {
        self.tableView.estimatedRowHeight = 350
        self.tableView.rowHeight = UITableView.automaticDimension
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControl.Event.valueChanged)

        // show personal feed
//        self.stopPaginationLoading = true
//        self.posts = []
//
//        // show personal feed
//        self.collection = Story.recents //SocialUserModel.current!.feed

//        self.loadData()
        let nib = UINib(nibName: "NewFeedTableViewCell", bundle: nil)
        self.tableView.register(nib, forCellReuseIdentifier: "NewFeedTableViewCell")
//        self.getfollowingsUsers()
    }
        
    override func viewDidAppear(_ animated: Bool) {
        self.getfollowingsUsers()
    }
    override func viewWillAppear(_ animated: Bool) {
        startObserveScrollingTop()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopObserveScrollingTop()

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: StoryTableViewCell.AutoplayMuteKey, object: nil)
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        if let lastIndex = self.tableView.indexPathsForVisibleRows?.last {
//            if lastIndex.row >= self.posts.count - 2 {
//                loadMore()
//            }
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let commentsCtrl = segue.destination as? CommentsTableViewController {
            let story = sender as? DatabaseReference
            commentsCtrl.storyId = story?.key
        }
        
        if let profileCtrl = segue.destination as? ProfileViewController {
            if let user = sender as? DatabaseReference, let key = user.key {
                profileCtrl.currentUser = SocialUserModel(key)
                profileCtrl.isFromSearch = true
            }
        }
    }
    
    // MARK: - Data
    
//    func observeNewItems(_ firstKey:DataSnapshot?) {
        // Listen for new posts in the Firebase database
//        newRef?.removeAllObservers()
//        newRef = self.collection.queryOrderedByKey()
//
//        if let startKey = firstKey?.key {
//            newRef = newRef?.queryStarting(atValue: startKey)
//        }
//
//        // Listen for new posts in the Firebase database
//        newRef?.observe(.childAdded, with: { (snapshot) in
//            if snapshot.key != firstKey?.key {
//                DispatchQueue.main.async(execute: {
//                    self.posts.insert(snapshot, at: 0)
//                    self.tableView.reloadData()
//                })
//            }
//        })
//    }
    
//    func loadData() {
//        if let storyId = singleStoryId {
//            let ref = Story.collection.child(storyId)
//            ref.observeSingleEvent(of: .value, with: { (snapshot) in
//                DispatchQueue.main.async(execute: {
//                    self.posts.insert(snapshot, at: 0)
//                    self.stopPaginationLoading = true
//                    print("Loaded \(snapshot.childrenCount) items")
//
//                    self.tableView.reloadData()
//                    self.refreshControl?.endRefreshing()
//                })
//
//            }) { (error) in
//                let alert = UIAlertController(title: kAlertErrorTitle, message: error.localizedDescription, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: kAlertErrorDefaultButton, style: .default) { (action) in })
//                self.present(alert, animated: true) {}
//            }
//
//        } else {
//            let ref = self.collection
//                .queryOrderedByKey()
//                .queryLimited(toLast: kPagination)
//
//            ref.observeSingleEvent(of: .value, with: { (snapshot) in
//                DispatchQueue.main.async(execute: {
//                    for child in snapshot.children {
//                        if let item = child as? DataSnapshot {
//                            self.posts.insert(item, at: 0)
//                        }
//                    }
//
//                    self.stopPaginationLoading = false
//                    self.lastKey = snapshot.children.allObjects.first as? DataSnapshot
//
//                    let firstKey = snapshot.children.allObjects.last as? DataSnapshot
//                    self.observeNewItems(firstKey)
//
//                    print("Loaded \(snapshot.childrenCount) items")
//
//                    self.tableView.reloadData()
//                    self.refreshControl?.endRefreshing()
//                })
//
//            }) { (error) in
//                let alert = UIAlertController(title: kAlertErrorTitle, message: error.localizedDescription, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: kAlertErrorDefaultButton, style: .default) { (action) in })
//                self.present(alert, animated: true) {}
//            }
//
//            // track for remove
//            oldRef?.removeAllObservers()
//            oldRef = self.collection
//            oldRef?.observe(.childRemoved, with: { (snapshot) in
//                DispatchQueue.main.async(execute: {
//                    for item in self.posts {
//                        if snapshot.key == item.key {
//                            // remove item from collection
//                            self.posts.remove(at: self.posts.index(of: item)!)
//                        }
//                    }
//
//                    self.tableView.reloadData()
//                })
//            })
//        }
//    }
    
//    func loadMore() {
//        // load more
//        if self.stopPaginationLoading == true || singleStoryId != nil {
//            return
//        }
//
//        var refPagination = self.collection.queryOrderedByKey().queryLimited(toLast: kPagination + 1)
//
//        if let last = self.lastKey {
//            refPagination = refPagination.queryEnding(atValue: last.key)
//
//            // load rest feed
//            refPagination.observeSingleEvent(of: .value, with: { (snapshot) -> Void in
//
//                print("Loaded more \(snapshot.childrenCount) items")
//
//                let items = snapshot.children.allObjects
//
//                if items.count > 1 {
//                    for i in 2...items.count {
//                        if let data = items[items.count-i] as? DataSnapshot {
//                            self.posts.append(data)
//                        }
//                    }
//
//                    self.lastKey = items.first as? DataSnapshot
//                    self.tableView.reloadData()
//                } else {
//                    self.stopPaginationLoading = true
//                    print("last item")
//                }
//            })
//        }
//    }

//    func activateCell() {
//        let center = CGPoint(x: view.center.x, y: view.frame.height/2 + self.tableView.contentOffset.y)
//        guard
//            let centeredIndexPath = tableView.indexPathForRow(at: center),
//            let storyCell = tableView.cellForRow(at: centeredIndexPath) as? StoryTableViewCell
//            else { return }
//
//        if activeCell != storyCell {
//            activeCell?.isPlaying = false
//            activeCell = storyCell
//            storyCell.isPlaying = true
//        }
//    }

    @objc func handleRefresh(refreshControl: UIRefreshControl) {
//        // reset states
//        self.lastKey = nil
//        self.stopPaginationLoading = true
//        self.posts = []
//
//        // reload data
//        loadData()
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//
//        // update empty view
//        if (self.posts.count == 0) {
//            self.tableView.backgroundView = emptyView
//        }
//
//        return self.posts.count
        
        return self.feedModel.count
//        return self.users.count
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if kAutoplayVideo {
//            activateCell()
//        }
//    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let identifier = "Cell"
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? StoryTableViewCell else {
//            return UITableViewCell()
//        }
//        let snap = self.posts[indexPath.row]
//
//        cell.ref = snap.ref
//        cell.storyRef = Story(snap.key).ref
//        cell.delegate = self
//        cell.cellIndex = indexPath.row
//
//        return cell
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewFeedTableViewCell", for: indexPath) as! NewFeedTableViewCell
//        if let userInfo = self.users[indexPath.row] as? SocialUserModel {
//            cell.userRef = userInfo.ref
//        }
        cell.configureCell(data: self.feedModel[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    // MARK: - Cell delegate
    
    func storyAction(_ data: DatabaseReference?) {
        if let story = data {
            Like.story(story)
        }
    }
    
    func storyDidLike(_ data: DatabaseReference?) {
        if let story = data {
            Like.toggle(story)
        }
    }
    
    func storyDidShare(_ data: DatabaseReference?) {
        
        if let key = data?.key {
            let story = Story(key)
            
            story.fetchInBackground(completed: { (model, success) in
                
                // try to get image first
                var items: [Any] = [
                    "by \(story.userName)"
                ]
                
                if story.videoUrl != nil {
                    items.append(story.videoUrl)
                } else if let imageUrl = URL(string: story.media) {
                    items.append(imageUrl)
                }
                
                let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
                self.present(activityViewController, animated: true) {
                    // ..
                }
            })
        }
    }
    
    func storyDidComment(_ data: DatabaseReference?) {
        self.performSegue(withIdentifier: "feed.comments", sender: data)
    }
    
    func openProfile(_ user: DatabaseReference?) {
        self.performSegue(withIdentifier: "show.profile", sender: user)
    }
    
    /* UserTableViewCellDelegate */
    
//    func onStoryRemoved() {
//        if let _ = singleStoryId {
//            self.navigationController?.popViewController(animated: true)
//        }
//    }
    
//    func storyMenu(_ story: DatabaseReference?, position:NSInteger) {
//        let menuController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//        let postedStory = Story(self.posts[position].key)
//
//        postedStory.fetchInBackground { (model, success) in
//
//            if !success {
//                let removeAction = UIAlertAction(title: "Remove the story", style: .destructive) { (action) in
//                    // remove from my feed
//                    let key = self.posts[position].key
//                    Story.removeStory(key)
//                    self.onStoryRemoved()
//                }
//                menuController.addAction(removeAction)
//            } else {
//
//                // delete for own stories
//                if SocialUserModel(postedStory.userId).isCurrent() {
//                    let removeAction = UIAlertAction(title: "Remove the story", style: .destructive) { (action) in
//                        // remove from my feed
//                        if let snap = self.posts[position].ref.key {
//                            Story.removeStory(snap)
//                        }
//                        self.onStoryRemoved()
//                    }
//                    menuController.addAction(removeAction)
//                }
//                    // hide or report for others
//                else {
//                    let reportAction = UIAlertAction(title: "Report", style: .destructive) { (action) in
//                        // 1. remove from my feed
//                        let snap = self.posts[position]
//                        snap.ref.removeAllObservers()
//                        snap.ref.removeValue()
//
//                        let body = "Please remove the story with id: \(snap.key), as not appropriate."
//
//                        // 2. send email with report
//                        if (MFMailComposeViewController.canSendMail()) {
//                            let email = MFMailComposeViewController()
//                            email.setSubject("Report a content")
//                            email.setMessageBody(body, isHTML: false)
//                            email.mailComposeDelegate = self
//                            email.setToRecipients([kReportEmail])
//                            self.present(email, animated: true, completion: nil)
//                        } else {
//                            let encodedBody = body.addingPercentEncoding(withAllowedCharacters:.urlHostAllowed) ?? ""
//
//                            if let mailurl = URL(string:"mailto:\(kReportEmail)?subject=\(encodedBody)") {
//                                UIApplication.shared.openURL(mailurl)
//                            }
//
//                            self.onStoryRemoved()
//                        }
//                    }
//
//                    menuController.addAction(reportAction)
//
//                    let hideAction = UIAlertAction(title: "Hide the story", style: .default) { (action) in
//                        // remove from my feed
//                        let snap = self.posts[position]
//                        snap.ref.removeAllObservers()
//                        snap.ref.removeValue()
//                        self.onStoryRemoved()
//                    }
//                    menuController.addAction(hideAction)
//                }
//            }
//
//            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//            menuController.addAction(cancelAction)
//
//            self.present(menuController, animated: true)
//        }
//
//    }
    
    var currentUser: SocialUserModel? = SocialUserModel.current
    private var database = DatabaseService() //Database
    private var feedModel = [FeedPostModel]()
    var users: NSMutableArray = []
}

extension FeedViewController : MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
//        self.onStoryRemoved()
    }
}

extension FeedViewController : UserTableViewCellDelegate {
    func didSelected(ref: DatabaseReference) {
        self.performSegue(withIdentifier: "show.profile", sender: ref)
    }
    func didAction(ref: DatabaseReference?, position: NSInteger) {
//        storyMenu(ref, position: position)
    }
}

struct FeedPostModel {
    let userName: String
    let notes: Note
}

extension FeedViewController {
    func getfollowingsUsers() {
        // load user profile and keep tracking update
        guard let user = self.currentUser else { return }
        
        let results: NSMutableArray = []
        user.followings.observeSingleEvent(of: .value, with: { (snapshot) in
            if let children = snapshot.children.allObjects as? [DataSnapshot] {
                for item in children {
                    debugPrint("The item", item)
                    results.insert(SocialUserModel(item.key), at: 0)
//                    self.getSpecificNotes(userId: item.key)
                }
                self.users = results
                
                for index in 0..<self.users.count {
                    if let userInfo = self.users[index] as? SocialUserModel {
                        self.feedModel.removeAll()
                        userInfo.ref.observe(.value, with: { (snapshot) in
                            let user = SocialUserModel(snapshot)
                            for note in user.notes {
                                if !(note.isPrivateNote ?? false) {
                                    let feedItem = FeedPostModel(userName: user.getName(), notes: note)
                                    self.feedModel.append(feedItem)
                                }
                                
                            }
//                            debugPrint("feed model count", self.feedModel.count)
                            self.tableView.reloadData()
                        })
                    }
                }
                self.tableView.reloadData()
            }
        })
    }
    
    func getSpecificNotes(userId: String) {
        database.getData(specificUserId: userId) { notes in
            let publicNotes = notes.filter { $0.isPrivateNote == false }
            debugPrint("The notes", publicNotes.first?.categoryName)
        }
    }

}
