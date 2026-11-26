//
//  NoteModel.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit

class NoteModel: NSObject {

    
    //MARK:- KEYS
    
    let kNOTE_TITLE       = "noteTitle"
    let kNOTE_DESCRIPTION = "noteDescription"
    
    
    //MARK:- OBJECTS
    
    var noteTitle       = ""
    var noteDescription = ""
    
    
    //MARK:- INITIALIZATION
    
    override init() { }
    
    init(dictData : [String : Any]) {
        self.noteTitle       = dictData[kNOTE_TITLE] as! String
        self.noteDescription = dictData[kNOTE_DESCRIPTION] as! String
    }
}
