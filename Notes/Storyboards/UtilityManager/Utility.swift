//
//  Utility.swift
//  Notes
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import Foundation
import UIKit
import SCLAlertView

//MARK:- UIALERTVIEW

func alertView(_ title : String?, _ message : String, _ buttons : [String], completionHandler : @escaping ((_ index : Int) -> Void)) {
    
    let alertViewController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    
    for (index, _) in buttons.enumerated() {
        alertViewController.addAction(UIAlertAction(title:  buttons[index], style: .default, handler: { (selectedButtonIndex) in completionHandler(index) }))
    }
    UIApplication.topViewController()?.present(alertViewController, animated: true, completion: nil)
}


func stringFromHtml(string: String) -> NSAttributedString? {
    do {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        if let d = data {
            let str = try NSAttributedString(data: d, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            
            return str
        }
    } catch { }
    return nil
}

func isThumbIDAllowed() -> Bool {
    if let flag = UserDefaults.standard.value(forKey: kIS_THUMB_ID_ALLOWED) as? Bool {
        return flag ? true : false
    }
    return false
}


func isSkipped() -> Bool {
    if let flag = UserDefaults.standard.value(forKey: kIS_SKIPPED) as? Bool {
        return flag ? true : false
    }
    return false
}


func saveImageToDocumentDirectory(_ chosenImage: UIImage, imageName : String) -> String? {
    let directoryPath =  NSHomeDirectory().appending("/Documents/")
    if !FileManager.default.fileExists(atPath: directoryPath) {
        do {
            try FileManager.default.createDirectory(at: NSURL.fileURL(withPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
    }

    let filepath = directoryPath.appending(imageName)
    let url = NSURL.fileURL(withPath: filepath)
    do {
        try chosenImage.jpegData(compressionQuality: 1.0)?.write(to: url, options: .atomic)
        return String.init("\(filepath)/\(imageName).jpg")
        
    } catch {
        print(error)
        print("file cant not be save at path \(filepath), with error : \(error)");
        return nil
    }
    
    //MARK: SCALert
    func showErrorAlert(strMessage:String){
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.showError("Error", subTitle: strMessage as String,closeButtonTitle: "OK")
        
    }
    func showSuccessAlert(strMessage:String){
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.showSuccess("Success", subTitle: strMessage as String,closeButtonTitle: "OK")
        
    }
    
    func showInfoAlert(strMessage:String){
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.showInfo("Alert", subTitle: strMessage as String,closeButtonTitle: "OK")
        
    }
}


