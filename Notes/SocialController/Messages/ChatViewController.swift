//
//  ChatContainerViewController.swift
//  Mustage
//
//  Created by Oleg Baidalka on 14/03/2017.
//  Copyright © 2017 Oleg Baidalka. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseAuthUI
import FirebaseDatabaseUI
import GoogleMobileAds

class ChatViewController : UIViewController, GADBannerViewDelegate {
    
    @IBOutlet weak var keyboardConstraint: NSLayoutConstraint!
    @IBOutlet weak var bannerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView?
    @IBOutlet weak var bannerView:GADBannerView?

    var recipientName = "Conversation" { didSet { if isViewLoaded { updateChatHeader() } } }
    private func updateChatHeader() {
        // Preserve the original system navigation bar and its standard back button.
        navigationItem.titleView = nil
        title = recipientName.isEmpty ? "Conversation" : recipientName
        if let bar = navigationController?.navigationBar {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .clear
            appearance.shadowColor = .clear
            appearance.titleTextAttributes = [.font: ApplazAppearance.headerFont, .foregroundColor: ApplazAppearance.ink]
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
            bar.tintColor = ApplazAppearance.accent
        }
    }

    var messagesViewController:MessagesViewController?
    
    var chatRef:DatabaseReference? {
        didSet {
            showTitle()
            showMessages()
            
            // reset unread count
            chatRef?.child("unread").setValue(0)
        }
    }
    var contactRef:DatabaseReference? {
        didSet {
            if let contact = contactRef {
                self.openChat(contact)

                // subscribe for notification from that user
                print("subscribe to: chat\(contact.key)")
                Messaging.messaging().subscribe(toTopic: "\(kTopicFeed)\(contact.key)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = [.top, .bottom]
        updateChatHeader()
        textView?.font = ApplazAppearance.font(16)
        textView?.textColor = ApplazAppearance.ink
        textView?.backgroundColor = .clear
        textView?.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 8)
        textView?.accessibilityLabel = "Message"
        if let composer = textView?.superview as? UIStackView {
            composer.isBaselineRelativeArrangement = false
            composer.isLayoutMarginsRelativeArrangement = true
            composer.layoutMargins = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
            composer.backgroundColor = UIColor.white.withAlphaComponent(0.92)
            composer.layer.cornerRadius = 18
            composer.layer.borderWidth = 1.5
            composer.layer.borderColor = ApplazAppearance.ink.withAlphaComponent(0.28).cgColor
            composer.heightAnchor.constraint(greaterThanOrEqualToConstant: 60).isActive = true
            keyboardConstraint.isActive = false
            composer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -12).isActive = true
            for constraint in view.constraints where constraint.firstItem as? UIView == composer {
                if constraint.firstAttribute == .leading { constraint.constant = 16 }
            }
            for constraint in view.constraints where constraint.secondItem as? UIView == composer && constraint.firstAttribute == .trailing { constraint.constant = 16 }
            if let send = composer.arrangedSubviews.compactMap({ $0 as? UIButton }).first {
                send.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)), for: .normal)
                send.tintColor = ApplazAppearance.accent
                send.accessibilityLabel = "Send message"
            }
        }
        if kAdMobEnabled {
            
            
            if let bannerView = self.bannerView  {
                bannerView.adUnitID = kAdMobUnitID
                bannerView.rootViewController = self
                
                let request = GADRequest()
//                request.testDevices = [kGADSimulatorID]
                bannerView.load(request)
            }
        } else {
            self.bannerHeightConstraint.constant = 0
            self.view.updateConstraints()
        }
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print(bannerView.debugDescription)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.isHidden = false
        updateChatHeader()
        
        // subscribe for Keyboard move
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(keyboardWillShow),
                       name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        nc.addObserver(self, selector: #selector(keyboardWillHide),
                       name: UIResponder.keyboardWillHideNotification, object: nil)

        // pause table animations
        Settings.tableViewAnimation = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.isHidden = false
        updateChatHeader()
        // show keyboard
        self.textView?.becomeFirstResponder()
        // clear all unread messages
        self.chatRef?.child("unread").removeValue()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        // unsubscribe for Keyboard move
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        nc.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {

        UIView.animate(withDuration: notification.keyboardDuration(), animations: {
            self.view.layoutIfNeeded()
            
            // resume table animations
            Settings.tableViewAnimation = .automatic
        })
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        
        UIView.animate(withDuration: notification.keyboardDuration(), animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? MessagesViewController {
            // should be as Embded controller (but could be other way)
            self.messagesViewController = controller
            showMessages()
        }
    }
    
    // MARK: - public
    func showTitle() {
        if let ref = self.chatRef {
            ref.observeSingleEvent(of: .value, with: { (data) in
                self.recipientName = data.stringValue("name") ?? data.stringValue("User Name") ?? "Conversation"
                
                // subscribe for notification from that user
                if let contact = data.stringValue("contact") {
                    print("subscribe to: chat\(contact)")
                    Messaging.messaging().subscribe(toTopic: "\(kTopicFeed)\(contact)")
                }
            })
        } else {
            self.recipientName = self.recipientName.isEmpty ? "Conversation" : self.recipientName
        }
    }
    
    func showMessages() {
        // keep sync
        if let chatKey = self.chatRef?.key {
            self.messagesViewController?.messagesRef = Database.database()
                .reference(withPath: kDataMessagesKey).child(chatKey)            
        } else {
            self.messagesViewController?.messagesRef = nil
        }
    }
    
    func openChat(_ contact:DatabaseReference) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        if user.uid == contact.key {
            return
        }
        
        // check if chat is exist
        let chatRef = Database.database().reference(withPath: kDataChatsKey)
        chatRef.child(user.uid).queryOrdered(byChild: "contact").queryEqual(toValue: contact.key)
            .observeSingleEvent(of: .value, with: { (snap) in
                if snap.hasChildren() {
                    print("Used chat: \(chatRef.ref)")
                    let child = snap.children.nextObject() as? DataSnapshot
                    self.chatRef = child?.ref
                } else {
                    contact.observeSingleEvent(of: .value, with: { (data) in
                        self.recipientName = data.values?["User Name"] as? String ?? "Conversation"
                    })
                }
        })
    }
    
    func createChat(_ contact:DatabaseReference, callback: @escaping (DatabaseReference?)->()) {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        if user.uid == contact.key {
            return
        }
        
        // check if chat is exist
        let chatRef = Database.database().reference(withPath: kDataChatsKey)
        chatRef.child(user.uid).queryOrdered(byChild: "contact").queryEqual(toValue: contact.key)
            .observeSingleEvent(of: .value, with: { (snap) in
                if snap.hasChildren() {
                    print("Used chat: \(chatRef.ref)")
                    let child = snap.children.nextObject() as? DataSnapshot
                    callback(child?.ref)
                    self.chatRef = child?.ref
                } else {
                    print("New chat created: \(chatRef.ref)")
                    // Create new chat
                    contact.observeSingleEvent(of: .value, with: { (data) in
                        if let contactData = data.value as? [String:Any] {
                            // add new chat
                            let chat = chatRef.child(user.uid).childByAutoId()
                            
                            guard let chatKey = chat.key, let contactKey = contact.key
                                else { return }

                            
                            // create group with name and contacts collection
                            let values = [
                                "name" : contactData["User Name"] ?? "",
                                "profile" : contactData["photo"] ?? "",
                                "contact" : contactKey
                            ]
                            
                            // current user chat
                            chat.updateChildValues(values, withCompletionBlock: { (error, ref) in
                                callback(ref)
                                self.chatRef = ref
                            })
                            
                            SocialUserModel.collection.child(user.uid).observeSingleEvent(of: .value, with: { (userdata) in
                                var username = user.displayName ?? chatKey
                                var photo = ""
                                
                                if let map = userdata.value as? [String:Any] {
                                    username = map["User Name"] as? String ?? username
                                    photo = map["photo"] as? String ?? ""
                                }
                                
                                // create recent for other participant
                                chatRef.child(contactKey).child(chatKey).updateChildValues([
                                    "name" : username,
                                    "profile" : photo,
                                    "contact" : user.uid])
                            })
                        }
                    })
                }
            })
    }
    
    func sendMessage(chat:DatabaseReference, message:String) {
        if let user = Auth.auth().currentUser?.uid, let chatKey = chat.key {
            let messageRef = Database.database().reference(withPath:kDataMessagesKey)
                .child(chatKey).childByAutoId()
            
            let value:[String:Any] = [
                "message" : message,
                "user_id" : user
            ]
            messageRef.updateChildValues(value)
        }
        
        self.textView?.text = nil // set it nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // 0.3 sec later
            self.messagesViewController?.tableView.scrollBottom(true)
        }
    }
}

extension ChatViewController {
    @IBAction func onSendMessage() {
        if let message = self.textView?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
            
            // create chat if not created
            if let chat = self.chatRef {
                self.sendMessage(chat: chat, message: message)
            } else if let contact = self.contactRef {
                self.createChat(contact, callback: { (chatref) in
                    if let chat = chatref {
                        self.sendMessage(chat: chat, message: message)
                    }
                })
            }
            
        }
    }
}
