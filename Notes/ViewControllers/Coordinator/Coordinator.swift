//
//  Coordinator.swift
//  Notes
//
//  Created by Andrei Yarash on 12/20/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import FirebaseAuth
import TOPasscodeViewController

struct SignInKeysItems {
    
    struct StoryboardID {
      //  static let mainViewController = "NoteCategoryListVC"
        static let mainViewController = "WelcomeViewController" // the opening of social feed page
        static let signInViewContoller = "SignInScene"
        static let signUpViewContoller = "SignUpViewController"
        static let purchaseIntroViewContoller = "IntroPurchaseVC"
    }
    
    struct LoginKeysUserDefaults {
        static let isLoginKeyFirebase = "isLoginKeyFirebase"
        static let isLoginKeyFB = "isLoginKeyFB"
    }
}

struct Coordinator {

    static func rootViewContoller(isFirstTime: Bool)->Void{
        Task { @MainActor in
        
        let nav = UINavigationController()
        nav.navigationBar.isHidden = true
        let app = UIApplication.shared.delegate as! AppDelegate
        if app.window == nil { app.window = UIWindow(frame: UIScreen.main.bounds) }
        _ = WellnessStore.shared
        _ = SubscriptionCenter.shared
        let root: UIViewController
        if !UserDefaults.standard.bool(forKey: "ApplazWelcomeSeen.v1") {
            root = WellnessOnboarding.welcome(navigation: nav)
        } else if Auth.auth().currentUser != nil {
            UserDefaults.standard.set(false, forKey: Guest_Key)
            root = UIStoryboard(name: "SocialMain", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController")
        } else if UserDefaults.standard.bool(forKey: Guest_Key) {
            root = WellnessOnboarding.home()
        } else {
            root = UIStoryboard(name: "Authorization", bundle: nil).instantiateViewController(withIdentifier: "SignInScene")
        }
        nav.setViewControllers([root], animated: false)
        app.window?.rootViewController = nav
        app.window?.makeKeyAndVisible()
        }
    }

    static func runPasscodeVC() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.presentPasscodeSetVC(false, kSET_PASSCODE)
    }
}
