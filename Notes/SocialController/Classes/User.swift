//
//  User.swift
//  Project
//
//  Created by Bossly on 10/13/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SocialUserModel : ModelBase {

    private static var _current:SocialUserModel?
    
    static var collection:DatabaseReference {
        return Database.database().reference().child(kUsersKey)
    }
    
    static var current:SocialUserModel? {
        if let auth = Auth.auth().currentUser {
            if _current == nil || auth.uid != _current!.ref.key {
                _current = SocialUserModel(auth.uid)
                _current?.fetchInBackground(completed: { (model, success) in
                })
            }
            
            return _current
        } else {
            return nil
        }
    }
    
    
    func getName() -> String {
        if name.isEmpty {
            return UserDefaults.standard.string(forKey: "User_Name") ?? kDefaultUsername
        }
        return name
    }

    private var _isFollowed:Bool = false
    
    var name: String = ""
    var photo:String = kDefaultProfilePhoto
    var notes: [Note] = []
    var bio: String = ""
    var token:String?
    var followersCount:UInt = 0
    var followingsCount:UInt = 0
    var postsCount:UInt = 0
    var isFollow:Bool {
        get { return _isFollowed }
    }
    
    // stories I posted
    var feed:DatabaseReference {
        get {
            return Database.database().reference().child("\(kUserFeedKey)/\(self.ref.key!)")
        }
    }
    
    var uploads:DatabaseReference {
        get {
            return Database.database().reference().child("\(kUploadsKey)/\(self.ref.key!)")
        }
    }

    // posts I liked
    var favorites:DatabaseReference {
        get {
            return Database.database().reference().child("\(kDataFavoritesKey)/\(self.ref.key!)")
        }
    }

    // followers - people who follow me
    var followers:DatabaseReference {
        get {
            return self.ref.child(kFollowersKey)
        }
    }

    // followigns - people followed by me
    var followings:DatabaseReference {
        get {
            return self.ref.child(kFollowinsKey)
        }
    }
    
    func follow() {
        if let current = SocialUserModel.current, self.ref.key != current.ref.key,
            let key = self.ref.key, let currentKey = current.ref.key {
            current.followings.child(key).setValue("true")
            self.followers.child(currentKey).setValue("true")
            _isFollowed = true
            
            fetchInBackground(completed: { (model, success) in
                // update data
            })
        }
    }
    
    func unfollow() {
        if let current = SocialUserModel.current, self.ref.key != current.ref.key,
            let key = self.ref.key, let currentKey = current.ref.key {
            current.followings.child(key).removeValue()
            self.followers.child(currentKey).removeValue()
            _isFollowed = false

            fetchInBackground(completed: { (model, success) in
                // update data
            })
        }
    }

    func followOtherUser(user_id: String) {
        if let current = SocialUserModel.current, current.ref.key != user_id, let currentKey = current.ref.key {
            // Update current user's followings to include the target user
            current.followings.child(user_id).setValue("true")
            
            // Update target user's followers to include the current user
            Database.database().reference().child(kUsersKey).child(user_id).child(kFollowersKey).child(currentKey).setValue("true")
            
            // Set as followed
            _isFollowed = true
            
            // Optional: Fetch the updated data in the background if needed
            fetchInBackground(completed: { (model, success) in
                // Update any additional UI or model states if needed
            })
        }
    }

    func unfollowOtherUser(user_id: String) {
        if let current = SocialUserModel.current, current.ref.key != user_id, let currentKey = current.ref.key {
            // Remove the target user from current user's followings
            current.followings.child(user_id).removeValue()
            
            // Remove current user from the target user's followers
            Database.database().reference().child(kUsersKey).child(user_id).child(kFollowersKey).child(currentKey).removeValue()
            
            // Set as not followed
            _isFollowed = false
            
            // Optional: Fetch the updated data in the background if needed
            fetchInBackground(completed: { (model, success) in
                // Update any additional UI or model states if needed
            })
        }
    }

    
    
    func isCurrent() -> Bool {
        if let current = SocialUserModel.current, self.ref.key != current.ref.key {
            return false
        } else {
            return true
        }
    }

    override func parent() -> DatabaseReference {
        return SocialUserModel.collection
    }
    
    override func loadData(snap: DataSnapshot, with complete: @escaping (Bool) -> Void) {
        if let value = snap.value as? [String: Any] {
//            self.name = value["name"] as? String ?? kDefaultUsername
            self.name = value["User Name"] as? String ?? (SocialUserModel.current?.getName() ?? "")
            self.photo = value["photo"] as? String ?? kDefaultProfilePhoto
            self.bio = value["bio"] as? String ?? ""

            /// Getting the notes.
            if let children = snap.children.allObjects as? [DataSnapshot] {
                for child in children {
                    if child.key == "Notes" {
                        self.saveNotes(mainSnapshot: child)
                    }
                }
            }
            
            let followers = value[kFollowersKey] as? [String: Any]
            let current = SocialUserModel.current?.ref.key
            _isFollowed = followers?.first { $0.key == current } != nil
            
            complete(true)
        } else {
            complete(false)
        }
    }
    
    func saveNotes(mainSnapshot: DataSnapshot) {
        var noteArray = [Note]()
        print("Main key:\(mainSnapshot.key)")
        for snapshot in mainSnapshot.children {
            
            var note = Note()
            var noteBodyArray = [NoteBody]()
            
            let snap = snapshot as! DataSnapshot
            let dictionaryData = snap.value as! [String : Any]
            let categoryName = dictionaryData["Category Name"] as? String
            let isPrivateNote = dictionaryData["isPrivateNote"] as? Bool ?? true
           
            for snapshot in snap.children {
                
                var noteBody = NoteBody()
                
                let snap = snapshot as! DataSnapshot
                let data = snap.value as? [String:Any]
                if let noteItems = data {
                    
                    let titleName = noteItems["Title name"] as? String
                    let noteName = noteItems["Note name"] as? String
                    let key = noteItems["Key"] as? String
                    
                    noteBody.noteKey = key
                    noteBody.titleName = titleName
                    noteBody.descriptionText = noteName
                    
                    
                    noteBodyArray.append(noteBody)
                }
            }
            note.noteBody = noteBodyArray
            note.categoryName = categoryName
            note.isPrivateNote = isPrivateNote
            note.categoryKey = snap.key
            noteArray.append(note)
            
//            print("note array: \(noteArray)")
//            print("Count note array: \(noteArray.count)")
        }
        
        self.notes = noteArray
    }
    
    func saveData() {
        self.ref.updateChildValues(["User Name": self.getName(),
                                    "bio": self.bio,
                                    "photo": self.photo])
    }
    
    func save(_ token: String) {
        guard let deviceUid = UIDevice.current.identifierForVendor?.uuidString else {
            return
        }
        
        self.ref.child(kTokensKey).child(deviceUid).setValue(token)
    }
}
