////
////  AppleAuth.swift
////  Whirlpost
////
////  Created by office on 22/06/20.
////  Copyright © 2020 Sevenstar Infotech. All rights reserved.
////
//
//import Foundation
//import FirebaseAuth
//import AuthenticationServices
//
//@available(iOS 13.0, *)
//struct AppleAuth {
//    
//    
//      func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//            print(error.localizedDescription)
//        }
//        
//        // ASAuthorizationControllerDelegate function for successful authorization
//        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//            if let appleIDCredential = authorization.credential as?  ASAuthorizationAppleIDCredential {
//                let userIdentifier = appleIDCredential.user
//                
//                let fullName = appleIDCredential.fullName?.givenName
//                let email = appleIDCredential.email
//                
//            print(fullName)
//                print(email)
//                
//                 DispatchQueue.main.async {
//                    
//                    let appleIDProvider = ASAuthorizationAppleIDProvider()
//                    appleIDProvider.getCredentialState(forUserID: userIdentifier) {  (credentialState, error) in
//                        switch credentialState {
//                        case .authorized:
//                            let email = appleIDCredential.email
////                            self.showLoader()
//                            if email == nil
//                            {
//
//                            }
//                            else
//                            {
//                                self.SocialEmailAddress = email!
//                                self.SocialName = "\(appleIDCredential.fullName!.givenName!)"
//                                if email!.contains("privaterelay.appleid.com")
//                                {
//
//                                }
//                                else
//                                {
//                                    self.SocialEmailAddress = email ?? ""
//                                }
//                                
//                            }
//                            self.Socialid = userIdentifier
//                            self.GetSocialData(mobile: self.SocialMobileNumber, provider: "apple", provider_id: self.Socialid, email: self.SocialEmailAddress)
//                         
//                            break
//                        case .revoked:
//                            
//                            break
//                        case .notFound:
//                            
//                            break
//                        default:
//                            break
//                        }
//                    }
//                }
//                
//                
//                
//            }
//        }
//
//
//
//        //For present window
//        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor
//        {
//            
//            return self.view.window!
//        }
//
//}
