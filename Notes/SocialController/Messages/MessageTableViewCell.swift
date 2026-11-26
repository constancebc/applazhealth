//
//  MessageTableViewCell.swift
//  Mustage
//
//  Created by Oleg Baidalka on 15/03/2017.
//  Copyright © 2017 Oleg Baidalka. All rights reserved.
//

import UIKit
import Firebase

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var messageView: UITextView?
    @IBOutlet weak var profileView: ProfileView?
    @IBOutlet weak var timeView: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        messageView?.font = ApplazAppearance.font(16)
        messageView?.textColor = ApplazAppearance.ink
        messageView?.backgroundColor = reuseIdentifier == "me" ? UIColor(red: 0.86, green: 0.89, blue: 0.98, alpha: 1) : UIColor.white.withAlphaComponent(0.82)
        messageView?.layer.cornerRadius = 16
        messageView?.layer.borderWidth = 1
        messageView?.layer.borderColor = ApplazAppearance.outline.cgColor
        messageView?.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        timeView?.font = ApplazAppearance.font(12)
        timeView?.textColor = ApplazAppearance.ink.withAlphaComponent(0.65)
    }

    var profileKey:UInt?
    var ref:DatabaseQuery?

    func showMessage(_ snap:DataSnapshot) {
        if let value = snap.values {
            self.messageView?.text = value["message"] as? String
            
            if let time = value["created"] as? TimeInterval {
                self.timeView?.text = Date(timeIntervalSince1970: time/1000).timeAgoSinceNow
            } else {
                self.timeView?.text = nil
            }

            self.messageView?.setNeedsUpdateConstraints()
            
            if let key = self.profileKey {
                self.ref?.removeObserver(withHandle: key)
            }

            if let userid = value["user_id"] as? String {
                self.ref = SocialUserModel(userid).ref
                self.profileKey = ref?.observe(.value, with: { (data) in
                    // profile picture
                    if let image = data.stringValue("photo"), let url = URL(string: image) {
                        self.profileView?.sd_setImage(with:url)
                    } else {
                        self.profileView?.image = UIImage(named: kDefaultProfilePhoto)
                    }
                })
            }
            
            self.setNeedsUpdateConstraints()
        }
    }
    
}
