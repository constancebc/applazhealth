//
//  NewFeedTableViewCell.swift
//  Whirlpost
//
//  Created by Sadaf Khan on 09/09/23.
//  Copyright © 2023 Sevenstar Infotech. All rights reserved.
//

import UIKit
import Firebase

class NewFeedTableViewCell: UITableViewCell {

    @IBOutlet private weak var userName: UILabel!
    @IBOutlet private weak var noteImage: UIImageView!
    @IBOutlet private weak var noteName: UILabel!
    
    private var handler:UInt? = nil

    var userRef:DatabaseReference? {
        willSet {
            resetCell()
            
            // unsubscribe
            if let _handler = handler {
                userRef?.removeObserver(withHandle: _handler)
            }
        }
        didSet {
            // subscribe
            handler = userRef?.observe(.value, with: { (snapshot) in
                let user = SocialUserModel(snapshot)
                self.setupCell(user: user)
            })
        }
    }
    
    private func resetCell() {
        userName.text = kDefaultUsername
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        noteImage.addCornerRadius(radius: 10)
    }
    
    func configureCell(data: FeedPostModel) {
        userName.text = data.userName
        noteName.text = data.notes.categoryName
    }
    
    private func setupCell(user: SocialUserModel) {
        userName.text = user.getName()
        debugPrint("cell mai users ke notes", user.notes.count)
    }
}
