//
//  Notification.swift
//  Notes
//
//  Created by Ghullam Abbas on 02/11/2024.
//  Copyright © 2024 Sevenstar Infotech. All rights reserved.
//




struct NotificationList {
    
    var photo: String?
    var userID: String
    var userName: String
    var noteKey: String
    var noteTitle: String
    var notificationType: NotificationType // Like or Comment
    var commentText: String? // Only needed for comments
    var timestamp: Double
    
    var parentCategoryName:String?
    var parentCategoryKey:String?
    var isPrivateNote: Bool?
    var noteDescriptionText:String?
    var isLiked: Bool = false
    var comments: [NoteComment]?
    var followings = [String]()
    var followers =  [String]()
    var bio: String?
    var likeCount: Int = 0
    var noteToken: String?
    var recipientID: String = ""
    var eventID: String = ""
    var collaborationNotebookID: String?
    var collaborationInvitationID: String?
}

enum NotificationType {
    case like
    case comment
    case notebookInvite
    case notebookAccepted
}

import UIKit
import FirebaseAuth
import FirebaseDatabase

/// Activity is derived ONLY from notes owned by the current account, never from feed posts.
final class ApplazActivityInbox {
    static let shared = ApplazActivityInbox()
    static let changed = Notification.Name("ApplazActivityInboxChanged")
    private(set) var notifications: [NotificationList] = []
    private(set) var unread = 0
    private var uid: String?
    private var reference: DatabaseReference?
    private var handle: DatabaseHandle?
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var names: [String: (String, String?)] = [:]
    private var generation = UUID()
    private var seenAt: Double = 0
    private var collaborationEvents: [NotificationList] = []
    func removeCollaborationEvent(_ id: String) {
        collaborationEvents.removeAll { $0.collaborationInvitationID == id }
        notifications.removeAll { $0.collaborationInvitationID == id }
        unread = notifications.filter { $0.timestamp > seenAt }.count
        publish()
    }
    func setCollaborationEvents(_ events: [NotificationList]) {
        let user = Auth.auth().currentUser?.uid
        collaborationEvents = events.filter { $0.recipientID == user }
        notifications.removeAll { $0.notificationType == .notebookInvite || $0.notificationType == .notebookAccepted }
        notifications = (notifications + collaborationEvents).sorted { $0.timestamp > $1.timestamp }
        unread = notifications.filter { $0.timestamp > seenAt }.count
        publish()
    }
    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in self?.bind(user?.uid) }
    }
    func start() { bind(Auth.auth().currentUser?.uid); Task { @MainActor in await CollaborationStore.shared.refresh() } }
    private func bind(_ userID: String?) {
        guard uid != userID || reference == nil else { return }
        if let handle { reference?.removeObserver(withHandle: handle) }
        uid = userID; generation = UUID(); names = [:]; notifications = []; collaborationEvents = []; unread = 0; reference = nil; handle = nil
        publish()
        guard let userID else { return }
        let ref = Database.database().reference().child("Users").child(userID)
        reference = ref
        let token = generation
        handle = ref.observe(.value) { [weak self] snapshot in
            guard let self, token == self.generation, Auth.auth().currentUser?.uid == userID else { return }
            self.seenAt = (snapshot.childSnapshot(forPath: "notificationReadAt").value as? Double) ?? 0
            var events: [NotificationList] = []
            for case let category as DataSnapshot in snapshot.childSnapshot(forPath: "Notes").children {
                for case let note as DataSnapshot in category.children {
                    guard let value = note.value as? [String: Any], let title = value["Title name"] as? String else { continue }
                    let likes = value["likes"] as? [String: Bool] ?? [:]
                    let times = value["likeTimestamps"] as? [String: Double] ?? [:]
                    for (actor, liked) in likes where liked && actor != userID {
                        let identity = self.names[actor]
                        var event = NotificationList(photo: identity?.1, userID: actor, userName: identity?.0 ?? "Someone", noteKey: note.key, noteTitle: title, notificationType: .like, timestamp: times[actor] ?? 0)
                        event.parentCategoryKey = category.key; event.parentCategoryName = category.childSnapshot(forPath: "Category Name").value as? String
                        event.noteDescriptionText = value["Note name"] as? String; event.recipientID = userID
                        event.eventID = "\(category.key)/\(note.key)/like/\(actor)"
                        events.append(event)
                    }
                    for item in value["comments"] as? [[String: Any]] ?? [] {
                        guard let actor = item["userID"] as? String, actor != userID, let text = item["commentText"] as? String else { continue }
                        var event = NotificationList(photo: item["userProfilePicture"] as? String, userID: actor, userName: item["userName"] as? String ?? "Someone", noteKey: note.key, noteTitle: title, notificationType: .comment, commentText: text, timestamp: item["timestamp"] as? Double ?? 0)
                        event.parentCategoryKey = category.key; event.parentCategoryName = category.childSnapshot(forPath: "Category Name").value as? String
                        event.noteDescriptionText = value["Note name"] as? String; event.recipientID = userID
                        event.eventID = "\(category.key)/\(note.key)/comment/\(actor)/\(event.timestamp)/\(text)"
                        events.append(event)
                    }
                }
            }
            self.notifications = (events + self.collaborationEvents).sorted { $0.timestamp > $1.timestamp }
            self.unread = self.notifications.filter { $0.timestamp > self.seenAt }.count
            self.publish()
            for actor in Set(events.filter { $0.notificationType == .like }.map(\.userID)) where self.names[actor] == nil {
                self.names[actor] = ("Someone", nil)
                Database.database().reference().child("Users").child(actor).observeSingleEvent(of: .value) { [weak self] profile in
                    guard let self, token == self.generation, self.uid == userID else { return }
                    let name = profile.childSnapshot(forPath: "User Name").value as? String ?? "Someone"
                    let photo = profile.childSnapshot(forPath: "photo").value as? String
                    self.names[actor] = (name, photo)
                    for i in self.notifications.indices where self.notifications[i].userID == actor {
                        self.notifications[i].userName = name; self.notifications[i].photo = photo
                    }
                    self.publish()
                }
            }
        }
    }
    func markRead() {
        guard let uid, Auth.auth().currentUser?.uid == uid else { return }
        seenAt = Date().timeIntervalSince1970
        reference?.child("notificationReadAt").setValue(seenAt)
        unread = 0; publish()
    }
    private func publish() { NotificationCenter.default.post(name: Self.changed, object: self) }
}
