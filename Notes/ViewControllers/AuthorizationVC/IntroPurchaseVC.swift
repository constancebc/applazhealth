//
//  IntroPurchaseVC.swift
//  Whirlpost
//
//  Created by Mahipal on 06/05/19.
//  Copyright © 2019 Sevenstar Infotech. All rights reserved.
//

import UIKit

class IntroPurchaseVC: UIViewController {

    var sharedObj: Shared?
    let iapObj = IAPHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sharedObj = Shared.sharedInstance
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // verify in app purchase
        if (self.sharedObj?.isReachable)! {

           // iapObj.verifyReceipt()>>>>>
           
            
            
            //iapObj.autoRenewableVerifyPurchase(isShowActivity: true)
            //iapObj.autoRenewableVerifyPurchase()
            //iapObj.autoRenewableGetInfo()
        }
    }
    
    func gotoDestination() {
        
        let statusAuthorization:Bool = UserDefaults.standard.bool(forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFirebase)
        let statusAuthorizationFB:Bool = UserDefaults.standard.bool(forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFB)
        
        if (statusAuthorization == true || statusAuthorizationFB == true){
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "NoteCategoryListVC") as! NoteCategoryListVC
            self.navigationController?.pushViewController(vc, animated: true)
            
        } else {
            
            let mainStoryboard = UIStoryboard(name: "Authorization", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
            self.navigationController?.pushViewController(vc, animated: true)
           
            /*
            let mainStoryboard = UIStoryboard(name: "Authorization", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "SignInScene") as! SignInViewController
            self.navigationController?.pushViewController(vc, animated: true)
            */
        }
    }
    
    @IBAction func startedAction(_ sender: Any) {
       
        if sharedObj!.isProductPurchased {
            
            gotoDestination()
            
        } else {
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = mainStoryboard.instantiateViewController(withIdentifier: "PurchaseIntroVC") as! PurchaseIntroVC
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        
       gotoDestination()
    }
}
