//
//  NoteCategoryModel.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit

class NoteCategoryModel: NSObject {

    
    //MARK:- KEYS
    
    let kNOTE_CATEGORY = "noteCategory"
    let kNOTE_MODEL    = "noteModel"
    
    
    //MARK:- OBJECTS
    
    var noteCategory = ""
    var noteModel    = [NoteModel]()
    
    
    //MARK:- INITIALIZATION
    
    override init() { }
    
    init(dictData : [String : Any]) {
        self.noteCategory = dictData[kNOTE_CATEGORY] as! String
        self.noteModel    = dictData[kNOTE_MODEL] as! [NoteModel]
    }
}
