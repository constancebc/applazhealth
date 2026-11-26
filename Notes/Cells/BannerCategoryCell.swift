//
//  BannerCategoryCell.swift
//  Notes
//
//  Created by Anand Verma on 04/11/23.
//  Copyright © 2023 Sevenstar Infotech. All rights reserved.
//

import UIKit
import Firebase

class BannerCategoryCell: UICollectionViewCell {

    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var profilePick: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleMessage: UILabel!

    var ref:DatabaseQuery?
    var profileKey:UInt?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setProfile(userId: String) {
        self.ref = SocialUserModel(userId).ref
        self.profileKey = ref?.observe(.value, with: { (data) in
            // profile picture
            if let image = data.stringValue("photo"), let url = URL(string: image) {
                self.profilePick?.sd_setImage(with:url)
            } else {
                self.profilePick?.image = UIImage(named: kDefaultProfilePhoto)
            }
            
            if let userName = data.stringValue("User Name") {
                self.userName.text = userName
            } else {
                self.userName.text = ""
            }
        })
    }

}
