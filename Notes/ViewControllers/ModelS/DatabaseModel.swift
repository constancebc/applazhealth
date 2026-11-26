//
//  DatabaseModel.swift
//  Whirlpost
//
//  Created by Andrei Yarash on 12/29/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import Foundation



struct UserEntity {
    var nameUser:String?
    var notes:[Note]?
    
}

struct Note {
    var categoryName:String?
    var categoryKey:String?
    var isPrivateNote: Bool?
    var noteBody:[NoteBody]?
}

struct NoteBody {
    var titleName:String?
    var descriptionText:String?
    var noteKey:String?
    var isLiked: Bool = false
    var comments: [NoteComment]?
    var likeCount: Int = 0
    var noteToken: String?
}

struct NoteList {
    
    var user_id:String?
    var nameUser:String?
    var parentCategoryName:String?
    var parentCategoryKey:String?
    var isPrivateNote: Bool?
    var noteTitleName:String?
    var noteDescriptionText:String?
    var noteKey:String?
    var isLiked: Bool = false
    var comments: [NoteComment]?
    var photo: String?
    var followings = [String]()
    var followers =  [String]()
    var bio: String?
    var likes = [String: Bool]()
    var likeCount: Int = 0
    var isFollow = false
    var noteToken: String?
}

struct NoteComment {
    var userID: String
    var userName: String
    var userProfilePicture: String
    var commentText: String
    var timestamp: Double

    init(userID: String, userName: String, userProfilePicture: String, commentText: String, timestamp: Double) {
        self.userID = userID
        self.userName = userName
        self.userProfilePicture = userProfilePicture
        self.commentText = commentText
        self.timestamp = timestamp
    }

    // Convert this to a dictionary to store in Firebase
    func toDictionary() -> [String: Any] {
        return [
            "userID": userID,
            "userName": userName,
            "userProfilePicture": userProfilePicture,
            "commentText": commentText,
            "timestamp": timestamp
        ]
    }
}


struct UserNameWithEmail {
    var username: String?
    var email: String?
    var account_disbale:String?
}
