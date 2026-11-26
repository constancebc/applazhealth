//
//  PurchaseIntroVC.swift
//  Whirlpost
//
//  Created by Mahipal on 05/05/19.
//  Copyright © 2019 Sevenstar Infotech. All rights reserved.
//

import UIKit

class PurchaseIntroVC: UIViewController {

    var sharedObj: Shared?
    let iapObj = IAPHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

       sharedObj = Shared.sharedInstance
    }
    
    func gotoNextVC() {
        
         Coordinator.rootViewContoller(isFirstTime: true)
    }
    
    @IBAction func DayTrial(_ sender: Any) {
        
        if (self.sharedObj?.isReachable)! {
            //iapObj.purchase()
            iapObj.autoRenewablePurchase()
            gotoNextVC()
            
        } else {
            
            DispatchQueue.main.async(execute: {
                
                let alert = UIAlertController(title: "", message: "Please check your internet connection and try again.", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    
                }))
                
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    @IBAction func restoreAction(_ sender: Any) {
        
        if (self.sharedObj?.isReachable)! {
            
            iapObj.restorePurchases()
             gotoNextVC()
            
        } else {
            
            DispatchQueue.main.async(execute: {
                
                let alert = UIAlertController(title: "", message: "Please check your internet connection and try again.", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                }))
                
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        
         gotoNextVC()
        //self.dismiss(animated: true, completion: nil)
    }

    @IBAction func termsAction(_ sender: Any) {
        
        guard let url = URL(string: "http://whirlpost.co/terms-and-conditions/") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func policyAction(_ sender: Any) {
        
        guard let url = URL(string: "http://whirlpost.co/privacy-policy-2/") else { return }
        UIApplication.shared.open(url)
    }
    
}
