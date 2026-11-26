//
//  FirebaseAuth.swift
//  Notes
//
//  Created by Andrei Yarash on 12/17/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import SCLAlertView
struct FirebaseAuthoriztion {
    
    static let sharedInstance = FirebaseAuthoriztion()
    weak var mainVC:UIViewController!
    let refuser = Database.database().reference().child("UsernamesWithEmail")
    
    func signUpFirebase( emailAddress email:String?, password pass:String?, completion: @escaping ((Result<AuthDataResult, Error>) -> ())) {
        
        guard let viewController = mainVC else {return}
        guard let emailAddress = email, let password = pass else {return}
        
        
        Auth.auth().createUser(withEmail: emailAddress, password: password) { (authResult, err) in
            if let error = err {
                completion(.failure(error))
                //                let alertVC = UIAlertController(title: "Sign up Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                //                let alertAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                //                alertVC.addAction(alertAction)
                //                DispatchQueue.main.async{
                //                    viewController.present(alertVC, animated: true, completion: nil)
                //                }
            } else {
                if let dataResult = authResult {
                    completion(.success(dataResult))
                }
                
                // I think succesfull login was presented, so need to save flag of registration further  it will be used to show welcome pop-up. NMaks
                //UserDefaults.standard.set(true, forKey: "isNeedToShowWelcomePopUp")
            }
            
            viewController.view.endEditing(true)
        }
    }
    
    func signInFirebase(with email: String?, password pass: String?, completion: (() -> Void)? = nil) {
        guard let viewController = mainVC, let email, let password = pass else { completion?(); return }
        let address = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Auth.auth().signIn(withEmail: address, password: password) { result, error in
            DispatchQueue.main.async {
                completion?()
                if let error {
                    let code = (error as NSError).code
                    let message = "\(error.localizedDescription)\n\nError code: \(code)"
                    let alert = UIAlertController(title: "Sign in Error", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    viewController.present(alert, animated: true)
                    return
                }
                guard let signedInUser = result?.user else { return }
                // Firebase authentication is sufficient to enter the app. Optional
                // profile metadata must not hold a valid session behind a network read.
                if let name = signedInUser.displayName, !name.isEmpty {
                    UserDefaults.standard.set(name, forKey: "User_Name")
                } else {
                    UserDefaults.standard.removeObject(forKey: "User_Name")
                }
                UserDefaults.standard.set(true, forKey: SignInKeysItems.LoginKeysUserDefaults.isLoginKeyFirebase)
                Coordinator.rootViewContoller(isFirstTime: false)

                func updateCachedName(_ name: String?) {
                    guard Auth.auth().currentUser?.uid == signedInUser.uid, let name, !name.isEmpty else { return }
                    UserDefaults.standard.set(name, forKey: "User_Name")
                }
                func loadLegacyName() {
                    Database.database().reference().child("Users").child(signedInUser.uid).child("User Name")
                        .observeSingleEvent(of: .value, with: { updateCachedName($0.value as? String) })
                }
                refuser.child(signedInUser.uid).observeSingleEvent(of: .value, with: { snapshot in
                    if let name = snapshot.childSnapshot(forPath: "username").value as? String, !name.isEmpty { updateCachedName(name) }
                    else { loadLegacyName() }
                }, withCancel: { _ in loadLegacyName() })
            }
        }
    }

    func updateUserPassword(email:String?) {
        guard let vc = mainVC else{return}
        
        guard let emailAddress = email else{
            
            let alertVC = UIAlertController(title: "Wrong User Email", message: "Please check your email address.", preferredStyle: .alert)
            
            let alertDoneAction = UIAlertAction(title: "OK", style: .destructive, handler: nil)
            
            alertVC.addAction(alertDoneAction)
            
            vc.present(alertVC, animated: true, completion: nil)
            
            return
            
        }
        
        Auth.auth().sendPasswordReset(withEmail: emailAddress) { (err) in
            if let error = err {
                let alertVC = UIAlertController(title: "Failed reset password", message: error.localizedDescription, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Continue", style: .default, handler: nil)
                alertVC.addAction(alertAction)
                self.mainVC.present(alertVC, animated: true, completion: nil)
            }
            
            let alertVC = UIAlertController(title: "Resert Password", message: "We have just sent you a password reset email. Please check your inbox and follow the instructionsto resert your password", preferredStyle: .alert)
            
            let alertDoneAction = UIAlertAction(title: "OK", style: .default, handler: { (_) in
                self.mainVC.navigationController?.popViewController(animated: true)
            })
            alertVC.addAction(alertDoneAction)
            
            vc.present(alertVC, animated: true, completion: nil)
        }
        
    }
    
    func logoutFirebaseAccount() {
        let auth = Auth.auth()
        do {
            try auth.signOut()
        } catch {
            print("Sign Out error: \(error.localizedDescription)")
        }
    }
    
    
    func updateAccountStatus(account_status:String,completionHandler:@escaping ( _ result:Bool) -> Void){
        
        guard let uid = Auth.auth().currentUser?.uid else{
            return
        }
        
        let obj:[String:String] = [
            "account_disable": "true"
        ]
        refuser.child(uid).updateChildValues(obj){(error, reference) in
            if error != nil {
                return
            } else {
                do {
                    completionHandler(true)
                } catch {
                    completionHandler(false)
                }
            }
        }
    }
    
    //Account Disbale error
    func showErrorAlert(strMessage:String){
        let appearance = SCLAlertView.SCLAppearance(
            showCloseButton: true,
            shouldAutoDismiss: false,
            hideWhenBackgroundViewIsTapped: true
        )
        let alertView = SCLAlertView(appearance: appearance)
        alertView.showError("Error", subTitle: strMessage as String,closeButtonTitle: "OK")
        
    }
}
