//
//  FacebookAuth.swift
//  Notes
//
//  Created by Andrei Yarash on 12/17/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseAuth

struct FacebookAuth {
   
    private let fbManager = LoginManager() //FBSDKLoginManager()
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func signInFacbook(_ vc:UIViewController) {
//        let userPermissions:[String] = ["email"]
        self.appDelegate.isFBAuthorization = true
        
        /*
        fbManager.logIn(withReadPermissions: userPermissions, from: vc) { (result, err) in
            
            if let error = err {
                fatalError("Crash with login in FB account: \(error.localizedDescription)")
            }
            guard let resultAuth = result else{return}
            
            if (resultAuth.isCancelled) {
                //self.appDelegate.isFBAuthorization = false
                vc.dismiss(animated: true, completion: nil)
            }else {
                
                if let tokenKey = resultAuth.token?.tokenString {
                    let credential = FacebookAuthProvider.credential(withAccessToken: tokenKey)
                    
                    Auth.auth().signInAndRetrieveData(with: credential, completion: { (authResult, err) in
                        
                        if let error = err {
                            fatalError("Crash with credential auth: \(error.localizedDescription)")
                        }
                        self.appDelegate.isFBAuthorization = false
                        UserDefaults.standard.set(true, forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFB)
                        
                        Coordinator.rootViewContoller(isFirstTime: false)
                    })
                }
            }
        }
        */
        
        let loginManager = LoginManager()
        
        loginManager.logIn(permissions: ["email"], from: vc) { result, error in
            
            
            if let error {
                fatalError("Crash with login in FB account: \(error.localizedDescription)")
            }
            
            guard let resultAuth = result else{return}
            
            if (resultAuth.isCancelled) {
                //self.appDelegate.isFBAuthorization = false
                vc.dismiss(animated: true, completion: nil)
            }else {
                
                if let tokenKey = resultAuth.token?.tokenString {
                    let credential = FacebookAuthProvider.credential(withAccessToken: tokenKey)
                    
                    Auth.auth().signIn(with: credential, completion: { (authResult, err) in
                        
                        if let error = err {
                            fatalError("Crash with credential auth: \(error.localizedDescription)")
                        }
                        self.appDelegate.isFBAuthorization = false
                        UserDefaults.standard.set(true, forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFB)
                        
                        Coordinator.rootViewContoller(isFirstTime: false)
                    })
                }
                
            }
            
            /*
            if let error = error {
                print("Encountered Erorr: \(error)")
                CommonMethods.hideMBProgressHud()
            } else if let result = result, result.isCancelled {
                print("Cancelled")
            } else {
                print("Logged In")
                
                // Start
                let graphRequest : GraphRequest = GraphRequest(graphPath: "me", parameters: ["fields":"id,location,name,first_name,last_name,picture.type(large),email,birthday,gender"])
                
                graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                    
                    if error != nil {
                        NSLog(error.debugDescription)
                        CommonMethods.hideMBProgressHud()
                        return
                    }
                    
                    if let userDict = result as? NSDictionary? {
                        
                        if let getUserID = userDict?.object(forKey: "id") as? String {
                            self.userSocialID = getUserID
                        }
                        
                        if let getUserName = userDict?.object(forKey: "name") as? String {
                            self.strSocialLoginName = getUserName
                            UserDefaults.standard.set(getUserName, forKey: AlertMessages.strUserDefaultUserName)
                        }
                        
                        if let getUserEmail = userDict?.object(forKey: "email") as? String {
                            self.strSocialLoginEmail = getUserEmail
                        }
                        
                        let urlPath: String = userDict?.value(forKeyPath: "picture.data.url") as? String ?? ""
                        
                        UserDefaults.standard.set(urlPath, forKey: AlertMessages.strUserDefaultUserProfileImage)
                        
                        let urlUserProfileImage = URL(string: urlPath)
                        
                        if let setURl = urlUserProfileImage {
                            DispatchQueue.main.async(execute: {
                                let setimage = UIImageView()
                                setimage.kf.setImage(with: setURl)
                            })
                        }
                        
                        self.strSocialLoginType = "facebook"
                        self.isSocialLogin = 1
                        
                        self.loginAction(self.btnLogin)
                        
                    }
                    
                    connection?.start()
                })
                
                // End
                /*
                 let connection = GraphRequestConnection()
                 
                 connection.add(GraphRequest(graphPath: "/me", parameters: ["fields":"id,location,name,first_name,last_name,picture.type(large),email,birthday,gender"])) { response, result, error   in
                 
                 if error != nil {
                 NSLog(error.debugDescription)
                 CommonMethods.hideMBProgressHud()
                 
                 return
                 }
                 
                 if let userDict = result as? NSDictionary? {
                 
                 if let getUserID = userDict?.object(forKey: "id") as? String {
                 self.userSocialID = getUserID
                 }
                 
                 if let getUserName = userDict?.object(forKey: "name") as? String {
                 self.strSocialLoginName = getUserName
                 UserDefaults.standard.set(getUserName, forKey: AlertMessages.strUserDefaultUserName)
                 }
                 
                 if let getUserEmail = userDict?.object(forKey: "email") as? String {
                 self.strSocialLoginEmail = getUserEmail
                 }
                 
                 let urlPath: String = userDict?.value(forKeyPath: "picture.data.url") as? String ?? ""
                 print(urlPath)
                 
                 UserDefaults.standard.set(urlPath, forKey: AlertMessages.strUserDefaultUserProfileImage)
                 
                 let urlUserProfileImage = URL(string: urlPath)
                 
                 if let setURl = urlUserProfileImage {
                 print(setURl)
                 
                 DispatchQueue.main.async(execute: {
                 let setimage = UIImageView()
                 setimage.kf.setImage(with: setURl)
                 })
                 }
                 
                 self.strSocialLoginType = "facebook"
                 self.isSocialLogin = 1
                 
                 self.loginAction(self.btnLogin)
                 
                 }
                 }
                 
                 connection.start()
                 
                 */
            }
            */
            
          
        }
       
    }
    
    func signOutFacebookAccount() {
            self.fbManager.logOut()
    
    }
}
