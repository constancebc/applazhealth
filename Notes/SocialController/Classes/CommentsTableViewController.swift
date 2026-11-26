//
//  CommentsTableViewController.swift
//  b03-ios
//
//  Created by Bossly on 9/11/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuthUI
import FirebaseDatabaseUI

class CommentsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UserTableViewCellDelegate {
    
    var comments:NSMutableArray! = nil
    var storyId:String! = ""
    
    @IBOutlet weak var keyboardConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentText: UITextView! {
        didSet {
            commentText.layer.cornerRadius = commentText.frame.height/2
            commentText.contentInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.comments = NSMutableArray()
        let query = Comment.collection.child(self.storyId).queryOrderedByKey()

        // Listen for new posts in the Firebase database
        query.observe(.childAdded, with: { (snapshot) -> Void in
            DispatchQueue.main.async(execute: { 
                self.comments.add(snapshot)
                let lastIndex = IndexPath(row: self.comments.count-1, section: 0)
                self.tableView.insertRows(at: [lastIndex], with:.bottom)
                self.tableView.scrollToRow(at: lastIndex, at: .bottom, animated: false)
            })
        })
        
        query.observe(.childRemoved) { (snapshot) in
            DispatchQueue.main.async(execute: {
                
                let index = self.comments.indexOfObject(passingTest: { (obj, idx, stop) -> Bool in
                    if let data = obj as? DataSnapshot, data.key.elementsEqual(snapshot.key) {
                        return true
                    }
                    return false
                })
                
                self.comments.removeObject(at: index)
                let lastIndex = IndexPath(row: index, section: 0)
                self.tableView.deleteRows(at: [lastIndex], with: .automatic)
            })
        }
        
        self.tableView.estimatedRowHeight = 250
        self.tableView.rowHeight = UITableView.automaticDimension
        
        NotificationCenter.default
            .addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default
            .addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.commentText.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let profileCtrl = segue.destination as? ProfileViewController {
            if let user = sender as? DatabaseReference, let key = user.ref.key {
                profileCtrl.currentUser = SocialUserModel(key)
            }
        }
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        let rect:CGRect = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue
        let duration = ((notification as NSNotification).userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue
        let newHeight: CGFloat
        
        if #available(iOS 11.0, *) {
            newHeight = view.safeAreaInsets.bottom - rect.height
        } else {
            newHeight = -rect.height
        }
        self.keyboardConstraint.constant = newHeight
        
        UIView.animate(withDuration: duration!, animations: { 
            self.view.layoutSubviews()
        }) 
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        let duration = ((notification as NSNotification).userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]! as AnyObject).doubleValue
        self.keyboardConstraint.constant = 0
        
        UIView.animate(withDuration: duration!, animations: {
            self.view.layoutSubviews()
        }) 
    }

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? CommentTableViewCell

        // Configure the cell...
        if let comment = self.comments.object(at: (indexPath as NSIndexPath).row) as? DataSnapshot {
            cell?.displayComment(comment)
            cell?.delegate = self
        }

        return cell ?? UITableViewCell()
    }
    
    @IBAction func onSend(_ sender: AnyObject) {
        if let commentText = self.commentText.text {
            Comment.sendComment(commentText, storyKey: self.storyId)
        }
        
        self.commentText.text = nil
    }
    
    /* UserTableViewCellDelegate */
    
    func didSelected(ref: DatabaseReference) {
        // none
        let menuController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        menuController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let removeAction = UIAlertAction(title: "Remove the comment", style: .destructive) { (action) in
            // remove from my feed
            ref.removeAllObservers()
            ref.removeValue()
        }
        
        ref.observeSingleEvent(of: .value) { (data) in
            
            if let value = data.value as? [String:Any] {
                // check if I'm allow to remove the comment
                if let userid = value["profile_id"] as? String {
                    if SocialUserModel(userid).isCurrent() {
                        menuController.addAction(removeAction)
                        self.present(menuController, animated: true, completion: nil)
                    }
                }
            } else {
                print("Error: Can't load comment data")
            }
        }
    }
    
    func didAction(ref: DatabaseReference?, position:NSInteger) {
        // none
    }
}
