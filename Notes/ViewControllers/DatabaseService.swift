//
//  DatabaseService.swift
//  Notes
//
//  Created by Andrei Yarash on 12/19/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase


struct DatabaseService {
    
    private let parent_Identifier = "Users"
    private let user_Name = "Default User_Name"
    private let category_Name = "Notebook"
    private let category_Title = "Journal Title"
    private let journey_Entry = "Journal Entry"
    private let usernamesWithEmail = "UsernamesWithEmail"
    var usernamesObserverHandle: DatabaseHandle?
    var databaseRef:DatabaseReference!
    
    private var user:User!
    
    func createEmptyNotebook(name: String, isPrivate: Bool, completion: @escaping (Result<Note, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "Applaz", code: 401, userInfo: [NSLocalizedDescriptionKey: "Sign in to create this notebook."])))
            return
        }
        let ref = Database.database().reference().child("Users").child(uid).child("Notes").childByAutoId()
        guard let key = ref.key else { return }
        ref.setValue(["Category Name": name, "Category Key": key, "isPrivateNote": isPrivate]) { error, _ in
            if let error { completion(.failure(error)) }
            else { completion(.success(Note(categoryName: name, categoryKey: key, isPrivateNote: isPrivate, noteBody: []))) }
        }
    }

    mutating func writeDataToDatabase(category:String = "Default Category", title:String = "Default title", note:String = "Default Note", isPrivateNote: Bool = false) {
        
        var user_ID = ""
        
        if let user = Auth.auth().currentUser {
            self.user = user
            self.databaseRef = Database.database().reference()
            user_ID = user.uid
        } else {return}
      
        guard let userName =  UserDefaults.standard.string(forKey: "User_Name") else {
        
            databaseRef.child(parent_Identifier).child(user_ID).child("User Name").setValue(self.user_Name)
            let firstRef = databaseRef.child(parent_Identifier).child(user_ID).child("Notes").childByAutoId()
            let secondRef = firstRef.childByAutoId()
            let noteToken = UserDefaults.standard.value(forKey: "noteToken") as? String ?? ""
            let noteBody = [ "Title name" : title, "Note name" : note, "Key" : secondRef.key, "noteToken": noteToken]
            let noteInfo = [ "Category Name" : category , "isPrivateNote": isPrivateNote, "Category Key" :  firstRef.key] as [String : Any]
            
            firstRef.setValue(noteInfo)
            secondRef.setValue(noteBody)
            return
        }
        databaseRef.child(parent_Identifier).child(user_ID).child("User Name").setValue(userName)
        
        let firstRef = databaseRef.child(parent_Identifier).child(user_ID).child("Notes").childByAutoId()
        let secondRef = firstRef.childByAutoId()
        let noteToken = UserDefaults.standard.value(forKey: "noteToken") as? String ?? ""
        let noteBody = [ "Title name" : title, "Note name" : note, "Key" : secondRef.key,"noteToken":  noteToken]
        let noteInfo = [ "Category Name" : category , "isPrivateNote": isPrivateNote, "Category Key" :  firstRef.key] as [String : Any]
        
        firstRef.setValue(noteInfo)
        secondRef.setValue(noteBody)
    }
    
   
    mutating func getAllNotes(completionHandler: @escaping ([Note]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completionHandler([])
            return
        }
        
        self.user = currentUser
        self.databaseRef = Database.database().reference()
        let userID = currentUser.uid
        
        databaseRef.child(parent_Identifier).child(userID).child("Notes").observeSingleEvent(of: .value) { mainSnapshot in
            var noteArray = [Note]()
            
            for case let categorySnapshot as DataSnapshot in mainSnapshot.children {
                if categorySnapshot.childSnapshot(forPath: "wellnessManaged").value as? Bool == true && categorySnapshot.childSnapshot(forPath: "isPrivateNote").value as? Bool == true { continue }
                guard let categoryData = categorySnapshot.value as? [String: Any] else { continue }
                
                var note = Note(
                    categoryName: categoryData["Category Name"] as? String ?? "",
                    categoryKey: categorySnapshot.key,
                    isPrivateNote: categoryData["isPrivateNote"] as? Bool ?? false,
                    noteBody: []
                )
                
                for case let noteSnapshot as DataSnapshot in categorySnapshot.children {
                    guard let noteData = noteSnapshot.value as? [String: Any] else { continue }
                    
                    let titleName = noteData["Title name"] as? String ?? ""
                    let noteName = noteData["Note name"] as? String ?? ""
                    let noteToken = noteData["noteToken"] as? String ?? ""
                    let noteKey = noteData["Key"] as? String ?? ""
                    let isLiked = noteData["isLiked"] as? Bool ?? false
                    let commentsData = noteData["comments"] as? [[String: Any]] ?? []
                    
                    let noteBody = NoteBody(
                        titleName: titleName,
                        descriptionText: noteName,
                        noteKey: noteKey,
                        isLiked: isLiked,
                        comments: commentsData.compactMap { commentData in
                            guard let userID = commentData["userID"] as? String,
                                  let userName = commentData["userName"] as? String,
                                  let userProfilePicture = commentData["userProfilePicture"] as? String,
                                  let commentText = commentData["commentText"] as? String,
                                  let timestamp = commentData["timestamp"] as? Double else { return nil }
                            return NoteComment(
                                userID: userID,
                                userName: userName,
                                userProfilePicture: userProfilePicture,
                                commentText: commentText,
                                timestamp: timestamp
                            )
                        },
                        noteToken: noteToken
                    )
                    
                    note.noteBody?.append(noteBody)
                }
                
                noteArray.append(note)
            }
            
            DispatchQueue.main.async {
                completionHandler(noteArray)
            }
        }
    }


    mutating func deleteFromDatabase(category:String?, title:String?) {
        
        var user_ID = ""
        if let user = Auth.auth().currentUser {
            self.user = user
            self.databaseRef = Database.database().reference()
            user_ID = user.uid
        } else {return}
        
        if let titleKey = title, let categoryKey = category {
            databaseRef.child(parent_Identifier).child(user_ID).child("Notes").child(categoryKey).child(titleKey).removeValue()
            
        } else if let categoryKey = category {
            
            databaseRef.child(parent_Identifier).child(user_ID).child("Notes").child(categoryKey).removeValue { (err, _) in
                if let error = err {
                    print(error.localizedDescription)
                }
            
            }
        }
    }
    
    
    
    /// specificUserId is the uid in the firebase database, used to get the specific user details.
    mutating func getAllFollowingUser(completionHandler:(@escaping([String])->Void)) {
        self.databaseRef = Database.database().reference()
        databaseRef.child(parent_Identifier).observe(.value) { (mainSnapshot) in
            var allUsers = [String]()
            for snapshot in mainSnapshot.children {
                let snap = snapshot as! DataSnapshot
                allUsers.append(snap.key)
            }
            DispatchQueue.main.async {
                completionHandler(allUsers)
            }
        }
    }
    
    /// specificUserId is the uid in the firebase database, used to get the specific user details.
    mutating func getAllUser(completionHandler:(@escaping([String])->Void)) {
        self.databaseRef = Database.database().reference()
        databaseRef.child(parent_Identifier).observe(.value) { (mainSnapshot) in
            var allUsers = [String]()
            for snapshot in mainSnapshot.children {
                let snap = snapshot as! DataSnapshot
                allUsers.append(snap.key)
            }
            DispatchQueue.main.async {
                completionHandler(allUsers)
            }
        }
    }
    
    func getNoteListData(specificUserId: String? = nil, completionHandler: @escaping ([NoteList]) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated.")
            return
        }
        
        let userID = specificUserId ?? user.uid
        let userRef = databaseRef.child("Users").child(userID)
        
        // Step 1: Fetch user details
        userRef.observeSingleEvent(of: .value) { userSnapshot  in
            guard let userData = userSnapshot.value as? [String: Any] else {
                print("Failed to retrieve user data.")
                return
            }
            let username = userData["User Name"] as? String ?? ""
            let photo = userData["photo"] as? String ?? ""
            let bio = userData["bio"] as? String ?? ""
            let followings = (userData["followings"] as? [String: String])?.compactMap { $0.key } ?? []
            let followers = (userData["followers"] as? [String: String])?.compactMap { $0.key } ?? []
            
            // Step 2: Fetch notes data for the user
            userRef.child("Notes").observeSingleEvent(of: .value) { mainSnapshot in
                var noteListArray = [NoteList]()
                var processedNoteKeys = Set<String>()
                
                for categorySnapshot in mainSnapshot.children {
                    guard let snap = categorySnapshot as? DataSnapshot else { continue }
                    let dictionaryData = snap.value as? [String: Any] ?? [:]
                    let categoryName = dictionaryData["Category Name"] as? String ?? ""
                    let isPrivateNote = dictionaryData["isPrivateNote"] as? Bool ?? false
                    
                    // Skip this category if the note is private
                    if isPrivateNote {
                        continue
                    }
                    
                    for noteSnapshot in snap.children {
                        guard let noteSnap = noteSnapshot as? DataSnapshot else { continue }
                        let noteData = noteSnap.value as? [String: Any]
                        
                        if let noteItems = noteData, let key = noteItems["Key"] as? String, !processedNoteKeys.contains(key) {
                            processedNoteKeys.insert(key)
                            
                            let titleName = noteItems["Title name"] as? String ?? ""
                            let noteName = noteItems["Note name"] as? String ?? ""
                            let noteToken = noteItems["noteToken"] as? String ?? ""
                            // Fetch like count and check if user has liked the note
                            let likeCount = noteItems["likeCount"] as? Int ?? 0
                            let userLikes = noteItems["likes"] as? [String: Bool]

                            var userLiked = false
                            for (user_id, value) in userLikes ?? [:] {
                                if user_id == userID {
                                    userLiked = true
                                }
                            }
                            // Fetch comments if available and map them to `NoteComment` objects
                            var comments: [NoteComment] = []
                            if let commentsData = noteItems["comments"] as? [[String: Any]] {
                                comments = commentsData.compactMap { commentData in
                                    guard let userID = commentData["userID"] as? String,
                                          let userName = commentData["userName"] as? String,
                                          let userProfilePicture = commentData["userProfilePicture"] as? String,
                                          let commentText = commentData["commentText"] as? String,
                                          let timestamp = commentData["timestamp"] as? Double else {
                                              return nil
                                          }
                                    return NoteComment(userID: userID, userName: userName, userProfilePicture: userProfilePicture, commentText: commentText, timestamp: timestamp)
                                }
                            }
                            
                            // Create NoteList instance with mapped data
                            let noteList = NoteList(
                                user_id: userID,
                                nameUser: username,
                                parentCategoryName: categoryName,
                                parentCategoryKey: snap.key,
                                isPrivateNote: isPrivateNote,
                                noteTitleName: titleName,
                                noteDescriptionText: noteName,
                                noteKey: key,
                                isLiked: userLiked,
                                comments: comments,
                                photo: photo,
                                followings: followings,
                                followers: followers,
                                bio: bio,
                                likes: userLikes ?? [:],
                                likeCount: likeCount,
                                noteToken: noteToken
                            )
                            
                            noteListArray.append(noteList)
                        }
                    }
                }
                
                // Step 3: Return the results with completionHandler
                DispatchQueue.main.async {
                    print("Fetched \(noteListArray.count) notes")
                    completionHandler(noteListArray)
                }
            }
        }
    }


    mutating func getNotificationListData(specificUserId: String? = nil, completionHandler: @escaping ([NotificationList]) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated.")
            return
        }
        
        self.databaseRef = Database.database().reference()
        let userID = specificUserId ?? user.uid
        let userRef = databaseRef.child("Users").child(userID).child("Notes")
        
        // Step 1: Fetch notes data to generate notifications
        userRef.observeSingleEvent(of: .value) { mainSnapshot in
            var notifications = [NotificationList]()
            
            for categorySnapshot in mainSnapshot.children {
                guard let snap = categorySnapshot as? DataSnapshot else { continue }
                
                for noteSnapshot in snap.children {
                    guard let noteSnap = noteSnapshot as? DataSnapshot else { continue }
                    let noteData = noteSnap.value as? [String: Any] ?? [:]
                    
                    let noteKey = noteData["Key"] as? String ?? ""
                    let noteTitle = noteData["Title name"] as? String ?? ""
                    
                    // Handle likes for notifications, using only userID
                    if let likes = noteData["likes"] as? [String: Bool] {
                        for likedUserID in likes.keys {
                            if likedUserID != userID {
                                let notification = NotificationList(
                                    userID: likedUserID,
                                    userName: "Unknown User",  // Placeholder or leave blank if name isn't available
                                    noteKey: noteKey,
                                    noteTitle: noteTitle,
                                    notificationType: .like,
                                    commentText: nil,
                                    timestamp: Date().timeIntervalSince1970
                                )
                                notifications.append(notification)
                            }
                        }
                    }
                    
                    // Handle comments for notifications, assuming comment data has user info
                    if let comments = noteData["comments"] as? [[String: Any]] {
                        for comment in comments {
                            if let commenterID = comment["userID"] as? String,
                               commenterID != userID {
                                let commenterName = comment["userName"] as? String ?? "Unknown User"
                                let commentText = comment["commentText"] as? String ?? ""
                                
                                let notification = NotificationList(
                                    userID: commenterID,
                                    userName: commenterName,
                                    noteKey: noteKey,
                                    noteTitle: noteTitle,
                                    notificationType: .comment,
                                    commentText: commentText,
                                    timestamp: Date().timeIntervalSince1970
                                )
                                notifications.append(notification)
                            }
                        }
                    }
                }
            }
            
            // Step 2: Return the notifications list
            DispatchQueue.main.async {
                print("Fetched \(notifications.count) notifications")
                completionHandler(notifications)
            }
        }
    }

    mutating func getSpecificNoteData(specificUserId: String? = nil, specificNoteId: String, completionHandler: @escaping (NoteList?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("User not authenticated.")
            completionHandler(nil)
            return
        }
        
        let userID = specificUserId ?? user.uid
        self.databaseRef = Database.database().reference()
        let userRef = databaseRef.child("Users").child(userID)
        
        // Step 1: Fetch user details
        userRef.observeSingleEvent(of: .value) { userSnapshot in
            guard let userData = userSnapshot.value as? [String: Any] else {
                print("Failed to retrieve user data.")
                completionHandler(nil)
                return
            }
            
            let username = userData["User Name"] as? String ?? ""
            let photo = userData["photo"] as? String ?? ""
            let bio = userData["bio"] as? String ?? ""
            let followings = (userData["followings"] as? [String: String])?.compactMap { $0.key } ?? []
            let followers = (userData["followers"] as? [String: String])?.compactMap { $0.key } ?? []
            
            // Step 2: Fetch the specific note data for the user
            userRef.child("Notes").observeSingleEvent(of: .value) { mainSnapshot in
                var specificNote: NoteList?
                
                // Iterate through the categories and notes to find the specific note
                for categorySnapshot in mainSnapshot.children {
                    guard let snap = categorySnapshot as? DataSnapshot else { continue }
                    
                    for noteSnapshot in snap.children {
                        guard let noteSnap = noteSnapshot as? DataSnapshot,
                              noteSnap.key == specificNoteId else { continue }
                        
                        let noteData = noteSnap.value as? [String: Any]
                        
                        if let noteItems = noteData {
                            let titleName = noteItems["Title name"] as? String ?? ""
                            let noteName = noteItems["Note name"] as? String ?? ""
                            let noteToken = noteItems["noteToken"] as? String ?? ""
                            let categoryName = (snap.value as? [String: Any])?["Category Name"] as? String ?? ""
                            let isPrivateNote = (snap.value as? [String: Any])?["isPrivateNote"] as? Bool ?? false
                            let likeCount = noteItems["likeCount"] as? Int ?? noteItems["likesCount"] as? Int ?? 0
                            let userLiked = (noteItems["likes"] as? [String: Bool])?[user.uid] ?? false
                            
                            // Handle comments: mapping them to `NoteComment` objects
                            var comments: [NoteComment] = []
                            if let commentsData = noteItems["comments"] as? [[String: Any]] {
                                comments = commentsData.compactMap { commentData in
                                    guard let userID = commentData["userID"] as? String,
                                          let userName = commentData["userName"] as? String,
                                          let userProfilePicture = commentData["userProfilePicture"] as? String,
                                          let commentText = commentData["commentText"] as? String,
                                          let timestamp = commentData["timestamp"] as? Double else {
                                              return nil
                                          }
                                    return NoteComment(userID: userID, userName: userName, userProfilePicture: userProfilePicture, commentText: commentText, timestamp: timestamp)
                                }
                            }
                            
                            specificNote = NoteList(
                                nameUser: username,
                                parentCategoryName: categoryName,
                                parentCategoryKey: snap.key,
                                isPrivateNote: isPrivateNote,
                                noteTitleName: titleName,
                                noteDescriptionText: noteName,
                                noteKey: specificNoteId,
                                isLiked: userLiked,
                                comments: comments,
                                photo: photo,
                                followings: followings,
                                followers: followers,
                                bio: bio,
                                likeCount: likeCount,
                                noteToken: noteToken
                            )
                            break // Stop once the specific note is found
                        }
                    }
                    
                    if specificNote != nil { break } // Exit outer loop if note found
                }
                
                // Step 3: Return the specific note with completionHandler
                DispatchQueue.main.async {
                    if let note = specificNote {
                        print("Fetched specific note with ID: \(specificNoteId)")
                    } else {
                        print("Note with ID \(specificNoteId) not found.")
                    }
                    completionHandler(specificNote)
                }
            }
        }
    }



    mutating func getData(specificUserId: String? = nil, completionHandler: @escaping ([Note]) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            print("User not authenticated.")
            completionHandler([]) // Return empty array if user is not authenticated
            return
        }
        
        self.user = currentUser
        self.databaseRef = Database.database().reference()
        
        // Use the specific user ID if provided; otherwise, use the current user's ID
        let userID = specificUserId ?? currentUser.uid
        
        // Observe the Notes data for the user
        databaseRef.child(parent_Identifier).child(userID).child("Notes").observe(.value) { mainSnapshot in
            var noteArray = [Note]()
            
            for child in mainSnapshot.children {
                guard let categorySnapshot = child as? DataSnapshot else { continue }
                
                if let categoryData = categorySnapshot.value as? [String: Any] {
                    if categoryData["wellnessManaged"] as? Bool == true && categoryData["isPrivateNote"] as? Bool == true { continue }
                    if userID != currentUser.uid && categoryData["isPrivateNote"] as? Bool == true { continue }
                    // Create a note object with category data
                    var note = Note(
                        categoryName: categoryData["Category Name"] as? String ?? "",
                        categoryKey: categorySnapshot.key,
                        isPrivateNote: categoryData["isPrivateNote"] as? Bool ?? false,
                        noteBody: []
                    )
                    
                    // Iterate through notes in the category
                    for noteChild in categorySnapshot.children {
                        guard let noteSnapshot = noteChild as? DataSnapshot else { continue }
                        
                        if let noteData = noteSnapshot.value as? [String: Any] {
                            
                            let titleName = noteData["Title name"] as? String ?? ""
                            let noteName = noteData["Note name"] as? String ?? ""
                            let noteToken = noteData["noteToken"] as? String ?? ""
                            let noteKey = noteData["Key"] as? String ?? ""
                            let isLiked = noteData["isLiked"] as? Bool ?? false
                            
                            // Parse comments if they are available in detailed dictionary format
                            var comments = [NoteComment]()
                            if let commentsData = noteData["comments"] as? [[String: Any]] {
                                comments = commentsData.compactMap { commentDict in
                                    guard let userID = commentDict["userID"] as? String,
                                          let userName = commentDict["userName"] as? String,
                                          let userProfilePicture = commentDict["userProfilePicture"] as? String,
                                          let commentText = commentDict["commentText"] as? String,
                                          let timestamp = commentDict["timestamp"] as? Double else {
                                        return nil
                                    }
                                    return NoteComment(
                                        userID: userID,
                                        userName: userName,
                                        userProfilePicture: userProfilePicture,
                                        commentText: commentText,
                                        timestamp: timestamp
                                    )
                                }
                            }
                            
                            // Create the note body and append to the note
                            let noteBody = NoteBody(
                                titleName: titleName,
                                descriptionText: noteName,
                                noteKey: noteKey,
                                isLiked: isLiked,
                                comments: comments,
                                noteToken: noteToken
                            )
                            
                            note.noteBody?.append(noteBody)
                        }
                    }
                    
                    // Append the note to the array
                    noteArray.append(note)
                }
            }
            
            // Return the final array of notes
            DispatchQueue.main.async {
                if noteArray.isEmpty {
                    print("No notes found.")
                } else {
                    print("Fetched \(noteArray.count) notes.")
                }
                completionHandler(noteArray)
            }
        }
    }

    
    
    mutating  func observeLikesAndComments(forUser userId: String, onUpdate: @escaping (String, Int?, [[String: Any]]?) -> Void) {
        let notesRef = self.databaseRef.child(parent_Identifier).child(userId).child("Notes")
        
        // Observe changes to likes and comments
        notesRef.observe(.childChanged, with: { snapshot in
            guard let noteData = snapshot.value as? [String: Any] else { return }
            
            // Safely unwrap the note key
            let noteKey = snapshot.key
            
            var likeCount: Int?
            var comments: [[String: Any]]?
            
            // Check if like count has changed
            if let newLikeCount = noteData["likesCount"] as? Int {
                likeCount = newLikeCount
            }
            
            // Check if comments have changed
            if let newComments = noteData["comments"] as? [[String: Any]] {
                comments = newComments
            }
            
            // Trigger update event with the retrieved data
            onUpdate(noteKey, likeCount, comments)
        })
    }
    
    mutating func updateNoteWithComment(commenting_user_id: String?, categoryKey: String?, noteKey: String?, newComment: NoteComment?, completion: ((Error?) -> Void)? = nil) {
        guard let userID = Auth.auth().currentUser?.uid,
              let ownerID = commenting_user_id, !ownerID.isEmpty,
              let categoryKey, !categoryKey.isEmpty, let noteKey, !noteKey.isEmpty,
              let newComment else {
            completion?(NSError(domain: "NoteComment", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign in and select a valid note to comment."]))
            return
        }
        let reference = Database.database().reference().child(parent_Identifier).child(ownerID).child("Notes").child(categoryKey).child(noteKey)
        reference.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                completion?(NSError(domain: "NoteComment", code: 2, userInfo: [NSLocalizedDescriptionKey: "This note is no longer available."]))
                return
            }
        reference.runTransactionBlock({ data in
            guard var value = data.value as? [String: Any] else { return TransactionResult.abort() }
            var comments = value["comments"] as? [[String: Any]] ?? []
            comments.append(newComment.toDictionary())
            value["comments"] = comments
            value["notificationCommentTrigger"] = ["userID": userID, "commentText": newComment.commentText, "timestamp": newComment.timestamp]
            data.value = value
            return TransactionResult.success(withValue: data)
        }, andCompletionBlock: { error, committed, _ in
            completion?(error ?? (committed ? nil : NSError(domain: "NoteComment", code: 2, userInfo: [NSLocalizedDescriptionKey: "This note is no longer available."])))
        })
        }, withCancel: { completion?($0) })
    }

    mutating func updateNoteWithLikeStatus(user_id: String, categoryKey: String?, noteKey: String?, isLiked: Bool, completion: @escaping (Int?, Error?) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid, !user_id.isEmpty,
              let categoryKey, !categoryKey.isEmpty, let noteKey, !noteKey.isEmpty else {
            completion(nil, NSError(domain: "NoteLike", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign in and select a valid note to like."]))
            return
        }
        let reference = Database.database().reference().child(parent_Identifier).child(user_id).child("Notes").child(categoryKey).child(noteKey)
        reference.observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                completion(nil, NSError(domain: "NoteLike", code: 2, userInfo: [NSLocalizedDescriptionKey: "This note is no longer available."]))
                return
            }
        reference.runTransactionBlock({ data in
            guard var value = data.value as? [String: Any] else { return TransactionResult.abort() }
            var likes = value["likes"] as? [String: Bool] ?? [:]
            let wasLiked = likes[userID] == true
            var count = value["likeCount"] as? Int ?? value["likesCount"] as? Int ?? likes.values.filter { $0 }.count
            if isLiked { likes[userID] = true } else { likes.removeValue(forKey: userID) }
            if wasLiked != isLiked { count = max(0, count + (isLiked ? 1 : -1)) }
            var times = value["likeTimestamps"] as? [String: Double] ?? [:]
            if isLiked && !wasLiked { times[userID] = Date().timeIntervalSince1970 }
            if !isLiked { times.removeValue(forKey: userID) }
            value["likeTimestamps"] = times
            value["likes"] = likes
            value["likeCount"] = count
            value["notificationLikeTrigger"] = isLiked ? ["userID": userID, "timestamp": Date().timeIntervalSince1970] : NSNull()
            data.value = value
            return TransactionResult.success(withValue: data)
        }, andCompletionBlock: { error, committed, snapshot in
            if let error { completion(nil, error) }
            else if committed { completion(snapshot?.childSnapshot(forPath: "likeCount").value as? Int, nil) }
            else { completion(nil, NSError(domain: "NoteLike", code: 2, userInfo: [NSLocalizedDescriptionKey: "This note is no longer available."])) }
        })
        }, withCancel: { completion(nil, $0) })
    }

    mutating func editDatabaseRecords(categoryNote:String?, titleNote:String?, categoryKey:String?, titleKey:String?, note:String?, isPrivateNote: Bool?, completionHandler:@escaping((Error?)->Void)) {
        // Change this func to toggle the flag value
        var user_ID = ""
        
        if let user = Auth.auth().currentUser {
            self.user = user
            self.databaseRef = Database.database().reference()
            user_ID = user.uid
        } else {return}
        
        if let category = categoryNote, let categoryNoteKey = categoryKey {
            var updatedValue = [String : Any]()
            
            if isPrivateNote != nil {
                updatedValue = ["Category Name" : category,
                                "isPrivateNote": isPrivateNote] as [String : Any]
            } else {
                updatedValue = ["Category Name" : category]
            }
            
            
            let ref = databaseRef.child(parent_Identifier).child(user_ID).child("Notes").child(categoryNoteKey)
           
            ref.updateChildValues(updatedValue) { (err, _) in
                DispatchQueue.main.async {
                    completionHandler(err)
                }
            }
            
        } else if let title = titleNote, let titleNoteKey = titleKey, let categoryNoteKey = categoryKey, let noteDescription = note {
            let updatedValue = ["Title name" : title, "Note name" : noteDescription]
            let ref = databaseRef.child(parent_Identifier).child(user_ID).child("Notes").child(categoryNoteKey)
            ref.child(titleNoteKey).updateChildValues(updatedValue) { (err, _) in
                DispatchQueue.main.async {
                    completionHandler(err)
                }
            }
            
            
        }else if let title = titleNote, let titleNoteKey = titleKey, let categoryNoteKey = categoryKey {
            let updatedValue = ["Title name" : title]
            let ref = databaseRef.child(parent_Identifier).child(user_ID).child("Notes").child(categoryNoteKey)
            ref.child(titleNoteKey).updateChildValues(updatedValue) { (err, _) in
                DispatchQueue.main.async {
                    completionHandler(err)
                }
            }
            
        }
    }
    

    mutating func writeNoteTitle(categoryKey: String?, titleNote:String?, noteDescription: String?) {
        // Change this func to toggle the flag value
        // Add flag here too, this is adding notes in the exiting note category
        var user_ID = ""
        if let user = Auth.auth().currentUser {
            self.user = user
            self.databaseRef = Database.database().reference()
            user_ID = user.uid
        } else {return}
        
        if let keyValue = categoryKey, let titleValue = titleNote, let noteValue = noteDescription {
            let firstRef = databaseRef.child(parent_Identifier).child(user_ID).child("Notes").child(keyValue)
            let secondRef = firstRef.childByAutoId()
            
            let noteBody = [ "Title name" : titleValue, "Note name" : noteValue, "Key" : secondRef.key ]
            
            secondRef.setValue(noteBody)
            
        }
        
    }
    
    mutating func writeUserNameWithEmail(username: String, email: String) {
        var user_ID = ""
        if let user = Auth.auth().currentUser {
            self.user = user
            self.databaseRef = Database.database().reference()
            user_ID = user.uid
        } else { return }
                
        let usernameNode = databaseRef.child(usernamesWithEmail).child(user_ID)
        let userNameValue = ["username": username, "email": email,"account_disable": "false"]
        
        usernameNode.setValue(userNameValue)
    }
    
    mutating func fetchAllUserNamesWithEmail(completion: @escaping ([UserNameWithEmail]) -> ()) {
        var user_ID = ""
        var usernamesArr: [UserNameWithEmail] = []
        
        if let user = Auth.auth().currentUser {
            self.user = user
            self.databaseRef = Database.database().reference()
            user_ID = user.uid
        } else {
            completion([])
            return
        }
        
        databaseRef.child(usernamesWithEmail).observe(.value) { usernamesSnapshot in
            for username in usernamesSnapshot.children {
                let usernameSnap = username as? DataSnapshot
                let dictData = usernameSnap?.value as! [String: Any]
                
                let username = dictData["username"] as? String ?? ""
                let email = dictData["email"] as? String ?? ""
                let account_disable = dictData["account_disable"] as? String ?? "false"
                usernamesArr.append(.init(username: username, email: email,account_disbale: account_disable))
            }
            
            DispatchQueue.main.async {
                completion(usernamesArr)
            }
        }
        
    }
    
    
    mutating func checkIfUserNameExistOrNot(userName: String, completion: @escaping (Bool) -> ()) {
        
        databaseRef = Database.database().reference().child(usernamesWithEmail)
        
        usernamesObserverHandle = databaseRef.observe(.value) { usernamesSnapshot in
            for username in usernamesSnapshot.children {
                let usernameSnap = username as? DataSnapshot
                let dictData = usernameSnap?.value as! [String: Any]
                let usernameLocal = dictData["username"] as? String ?? ""
                if userName == usernameLocal {
                    completion(true)
                    return
                }
            }
            completion(false)
        }
        
    }
    func removeFirebaseObserver() {
        if let observerHandle = usernamesObserverHandle {
            databaseRef.removeObserver(withHandle: observerHandle)
        }
    }
}

