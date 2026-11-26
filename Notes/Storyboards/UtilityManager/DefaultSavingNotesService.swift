//
//  DefaultSavingNotesService.swift
//  Whirlpost
//
//  Created by Andrei Yarash on 2/21/19.
//  Copyright © 2019 Sevenstar Infotech. All rights reserved.
//

import Foundation


struct DefaultSavingLogicNote {
    
    static let shared:DefaultSavingLogicNote = DefaultSavingLogicNote()
    
   func savingNoteBody(titleName:String,descriptionText:String) -> NoteBody {
        var noteBody = NoteBody()
        noteBody.descriptionText = descriptionText
        noteBody.titleName = titleName
        
        return noteBody
    }
    
     func savingNote(categoryName:String,titleName:String, descriptionText:String, isPrivateNote: Bool = false) -> Note {
        let noteBody = NoteBody.init(titleName: titleName, descriptionText: descriptionText, noteKey: nil)
        let note = Note.init(categoryName: categoryName, categoryKey: nil, isPrivateNote: isPrivateNote, noteBody: [noteBody])
        return note
    }
   
    
}
