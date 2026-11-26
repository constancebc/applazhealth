//
//  NoteCategoryTBLViewCell.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import TTTAttributedLabel


//MARK:- NOTE CATEGORY

class NoteCategoryTBLViewCell: UITableViewCell {

    
    //MARK:- OBJECTS & OUTLETS
    
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var lblNoteCategoryTitle: UILabel!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    
    //MARK:- CELL SETUP
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
        backGroundView.layer.cornerRadius = 16
        backGroundView.layer.cornerCurve = .continuous
        backGroundView.layer.borderWidth = 1
        backGroundView.layer.borderColor = ApplazAppearance.outline.cgColor
        
//        self.backgroundColor = .clear
//        self.contentView.backgroundColor = .clear
//       self.layoutMargins = UIEdgeInsets.init(top: 30, left: 0, bottom: 30, right: 0)
        
//        self.backGroundView.layer.borderColor = kBORDER_COLOR.cgColor
//        self.backGroundView.layer.borderWidth = 1.0
//        self.backGroundView.layer.cornerRadius = 5.0
//        self.backGroundView.clipsToBounds = true
        
        self.btnShare.madeCornerCircularWithShadow()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func btn_Share(_ sender: Any) {
    }
}


//MARK:- NOTE TITLE

class NoteTitleBLViewCell: UITableViewCell {
    
    
    //MARK:- OBJECTS & OUTLETS
    
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var lblNoteTitle: UILabel!
    @IBOutlet weak var btnUpdate: UIButton!
    @IBOutlet weak var btnDelete: UIButton!
    
    
    //MARK:- CELL SETUP
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.selectionStyle = .none
//        
//        self.backgroundColor = .clear
//        self.contentView.backgroundColor = .clear
//        
//      
//        self.backGroundView.layer.borderColor = kBORDER_COLOR.cgColor
//        self.backGroundView.layer.borderWidth = 1.0
        self.backGroundView.layer.cornerRadius = 16
        self.backGroundView.layer.cornerCurve = .continuous
        self.backGroundView.layer.borderWidth = 1
        self.backGroundView.layer.borderColor = ApplazAppearance.outline.cgColor
        self.backGroundView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}



//MARK:- NOTE DESCRIPTION

class NoteDescriptionTBLViewCell: UITableViewCell {
    
    
    //MARK:- OBJECTS & OUTLETS
    
    @IBOutlet weak var NoteImageView: UIImageView!
    @IBOutlet weak var backGroundView: UIView!
    @IBOutlet weak var lblNoteTitle: UILabel!
    @IBOutlet weak var lblNoteDescription: UILabel!
    
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    //MARK:- CELL SETUP
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        self.selectionStyle = .none
//
//        self.backgroundColor = .clear
//        self.contentView.backgroundColor = .clear
//        
//        self.backGroundView.layer.borderWidth = 1.0
//        self.backGroundView.layer.borderColor = kBORDER_COLOR.cgColor
        self.backGroundView.layer.cornerRadius = 12.0
        self.backGroundView.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
