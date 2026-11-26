//
//  UIViewController+Extension.swift
//  Whirlpost
//
//  Created by Sadaf Khan on 26/08/23.
//  Copyright © 2023 Sevenstar Infotech. All rights reserved.
//

import UIKit

extension UIViewController {
    
    typealias CompletionBlock = (_ bool:Bool)->Void
    
    func alertPermissionMessage(message:String, callback:@escaping CompletionBlock){
        
        let alert = UIAlertController(title: kAppName, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
            UIAlertAction in
            callback(true)
            NSLog("OK Pressed")
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
            callback(false)
            NSLog("Cancel Pressed")
        }
        
        // Add the actions
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func alertPermissionMessageSingleButton(message: String, callback:@escaping CompletionBlock){
        
        let alert = UIAlertController(title: kAppName, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
            UIAlertAction in
            callback(true)
            NSLog("OK Pressed")
        }

        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func normal_AlertMessage(title: String = kAppName,
                             message: String,
                             okButtonTitle: String = "OK") {
        let alert_controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let ok_action = UIAlertAction(title: okButtonTitle, style: UIAlertAction.Style.default, handler: nil)
        alert_controller.addAction(ok_action)
        self.present(alert_controller, animated: true, completion: nil)
    }
    
}
