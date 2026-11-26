//
//  String.swift
//  Sarahah
//
//  Created by SevenStar Infotech on 18/08/17.
//  Copyright © 2017 SevenStar Infotech. All rights reserved.
//

import Foundation


extension String {

    func setAttributetext(fontsize:Double,fontName:String)->NSAttributedString?{
        do {
            let strHtml = "<span style=\"font-family: \(fontName); font-size: \(fontsize)\">\(self)</span>"
            let attr = try NSMutableAttributedString(
                data: strHtml.data(using: .unicode, allowLossyConversion: true)!,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil)
                
            return attr
        } catch let error as NSError {
            print(error.localizedDescription)
            return  nil
        }
    }

    
    
    func removeNull()->String {
        if(self.characters.count==0){
            return ""
        }
        else if(self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)=="<null>"||self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)=="(null)") {
            return ""
        }
        else {
            return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }
    }

    func removeHTMLSpace()->String {
        if(self.characters.count==0){
            return ""
        }
//        else if(self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)=="<null>"||self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)=="(null)") {
//            return ""
//        }
        else if (self as NSString).contains("&nbsp;") {
            return (self as NSString).trimmingCharacters(in: CharacterSet.init(charactersIn: "&nbsp;"))
            //self.trimmingCharacters(in: CharacterSet.init(contentsOfFile: "&nbsp;")!)
            //self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }
        else {
            return self
        }
    }
    
    
    //MARK:- E-MAIL VALIDATION
    
    func isValidEmail() -> Bool {
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).uppercased() + dropFirst()
    }
        
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
