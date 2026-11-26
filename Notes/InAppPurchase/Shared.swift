//
//  Shared.swift
//  CredDirectory
//
//  Created by Mahipal on 12/4/17.
//  Copyright © 2017 Mahipal. All rights reserved.
//

import UIKit
import Foundation

import ReachabilitySwift
import MBProgressHUD

class Shared: NSObject {
    
    static let sharedInstanceObj = sharedInstance
    var reachability: Reachability?
    var isReachable: Bool?
    var currentDevie = "iPhone"
    var isProductPurchased = false
    
    //var hud: MBProgressHUD = MBProgressHUD()
    var hud: MBProgressHUD?
    var iapObj: IAPHelper?
    
    fileprivate override init() {
        
        super.init()
        
        //Reachability
        do {
            
            reachability = Reachability.init()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged(_:)), name: ReachabilityChangedNotification, object: reachability)
        do {
            try reachability!.startNotifier()
        } catch {
            
        }
    }
    
    class var sharedInstance: Shared {
        
        struct Static {
            static var instance: Shared?
        }
        
        if Static.instance == nil {
            Static.instance = Shared()
        }
        
        return Static.instance!
    }
    
    //Self delegate
    @objc func reachabilityChanged(_ note: Notification) {
        
        guard let reachability = note.object as? Reachability else {
            return
        }
        
        if reachability.isReachable {
            
            // WS call
            isReachable = true
            
            if reachability.isReachableViaWiFi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            
            if iapObj == nil {
                iapObj = IAPHelper()
            }
            
            //iapObj?.verifyReceipt()
            //iapObj?.autoRenewableVerifyPurchase(isShowActivity: false)
            //iapObj?.restorePurchases()
            
            //iapObj?.autoRenewableVerifyPurchase()
            //iapObj?.restorePurchases()
            
        } else {
            print("Not reachable")
            
            isReachable = false
        }
    }

    func showMBProgressHudView() {
        /*
        DispatchQueue.main.async(execute: {
            //self.hideMBProgressHud()
            self.hud = MBProgressHUD.showAdded(to: Shared.getTopViewController().view, animated: true)
        })
        */
    }
    
    // MARK: - Show / hide progresshud
    func hideMBProgressHud() {
        /*
        DispatchQueue.main.async(execute: {
            self.hud?.hide(animated: true)
        })
        */
    }
    
    class func getTopViewController() -> UIViewController {
        
        var viewController = UIViewController()
        
        if let viewObj =  UIApplication.shared.delegate?.window??.rootViewController {
            
            viewController = viewObj
            var presented = viewObj
            
            while let top = presented.presentedViewController {
                presented = top
                viewController = top
            }
        }
        return viewController
    }
}

extension Notification.Name {
    static let verifiySubscription = Notification.Name("verifiySubscription")
}
