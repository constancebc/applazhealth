//
//  AppDelegate.swift
//  Whirlpost
//
//  Created by Sevenstar Infotech on 07/02/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import TOPasscodeViewController
import LocalAuthentication
import AudioToolbox
import Firebase
import FBSDKCoreKit
import UserNotifications
import SwiftyStoreKit
import FirebaseAuthUI
import FirebaseDatabaseUI
import GoogleMobileAds
import FirebaseCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TOPasscodeViewControllerDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    private var privacyCover: UIImageView?
    var _client: FirebaseClient?
    
    var isBiometricsAvailable = false
    var arrLoginCredential = [Any]()
    // i change false to true
    var isLoggedIn = false
    var isStart = false
    var isConformPasscode = false
    var isFBAuthorization = false
    var passcodeViewController : TOPasscodeViewController?
    var strPasscode = ""
    var isForeground = false
    
    var sharedObj: Shared?
    var previousComments: [String: Any] = [:]
    var previousLikes: [String: Any] = [:]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApplazAppearance.install()
        // we hide status bar when splash scene is running and show when loading first scene of App
        UIApplication.shared.isStatusBarHidden = false
        
        sharedObj = Shared.sharedInstance
        
        FirebaseApp.configure()
        registerPushNotification()
        
        setupIAP()
        
        (DBManager.sharedManager() as AnyObject).createEditableCopyOfSQLIteIfNeeded()
        
        // The scene delegate creates the window and restores the root controller.

        
        // Google services
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        //print("Google Mobile Ads SDK version: " + GADMobileAds.sharedInstance().sdkVersion)
        _ = self.isBiomatriAvailable()
        
        if isSkipped() {
            return true
        }
        self.isLoggedIn = self.getLoginCredential()
        
        //Mark :  Changes here Nimesh
        
        //        if !self.isLoggedIn {
        //
        //            self.presentPasscodeSetVC(false, kSET_PASSCODE)
        //
        //        } else {
        //            self.presentPasscodeSetVC(false, "Enter Passcode")
        //        }
        self.isStart = true
    
        
        
        return true
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        let handledFacebook:Bool = FBSDKApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        
        let handledFacebook:Bool = ApplicationDelegate.shared.application(app, open: url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        
        let sourceApplication = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String
        
        if (handledFacebook) {
            return true
        } else if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        else{
            return false
        }
        
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        self.isForeground = false
        
        if self.getLoginCredential() {
            privacyCover?.removeFromSuperview()
            guard let window else { return }
            let cover = UIImageView(frame: window.bounds)
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cover.image = UIImage(named: "lock_screen")
            cover.contentMode = .scaleAspectFill
            cover.isUserInteractionEnabled = false
            window.addSubview(cover)
            privacyCover = cover
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        //Mark :  Changes here Nimesh
        
        self.isLoggedIn = self.getLoginCredential()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        privacyCover?.removeFromSuperview()
        privacyCover = nil
        if !self.isForeground {
          
            self.isStart = false
        }
        isForeground = true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    //MARK:- GET LOGIN CREDENTIAL
    
    func getLoginCredential() -> Bool{
        
        var isLoggedIn = false
        self.arrLoginCredential = (DBManager.sharedManager() as AnyObject).getResultForSQLQuery("select passcode from login") as! [Any]
        
        if self.arrLoginCredential.count > 0 {
            if self.isFBAuthorization {
                return false
            } else {
                isLoggedIn = true
            }
            
        }
        return isLoggedIn
    }
    
    func getSocialWelcomePage() {
        let storyboard = UIStoryboard(name: "SocialMain", bundle: Bundle.main)
        let rootController = storyboard.instantiateInitialViewController() as? UINavigationController

        // get first view controller and set the client to use
        let controller = rootController?.topViewController as? WelcomeViewController
        let client = FirebaseClient().setup() // initialize client
        controller?.client = client // set the client to use
        
        _client = client
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = rootController
        window?.makeKeyAndVisible()
    }
    
    //MARK:- CHECK IS BIOMATRIC AVAILABLE OR NOT
    
    func isBiomatriAvailable() -> Bool {
        let authContext : LAContext = LAContext()
        var error: NSError?
        self.isBiometricsAvailable = authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        
        return self.isBiometricsAvailable
    }
    
    
    //MARK:- TOPASSCODE VIEW CONTROLLER SETUP
    func presentPasscodeSetVC(_ isAnimated : Bool, _ title : String) {
        
        self.passcodeViewController = TOPasscodeViewController(style: .translucentDark, passcodeType: .fourDigits)
        self.passcodeViewController?.delegate = self
        self.passcodeViewController?.allowBiometricValidation = APP_DELEGATE.isBiomatriAvailable()
//        self.passcodeViewController?.title = title
//        self.passcodeViewController?.thumbIDYPosition = thumbID_YPosition
        self.passcodeViewController?.biometricButton.isHidden = isThumbIDAllowed() ? false : true
        
        if APP_DELEGATE.isBiomatriAvailable() {
            self.passcodeViewController?.biometryType = .touchID
        }
        
        if self.arrLoginCredential.count == 0 {
            
            let view = UIApplication.topViewController()?.view
            
            let xPosition = ((view?.frame.size.width)! / 2) - 25
            let yPosition = IS_IPHONE ? cancelBTN_YPosition : (((view?.frame.size.height)! / 4) * 3) + (IS_IPAD_PRO ? 0 : 20)
            
            let btnSkip : UIButton = UIButton(frame: CGRect(x: xPosition, y: yPosition, width: 50, height: 35))
            btnSkip.setTitle("Skip", for: .normal)
            btnSkip.setTitleColor(.white, for: .normal)
            btnSkip.addTarget(self, action: #selector(self.btnSkipPressed(_:)), for: .touchUpInside)
            self.passcodeViewController?.view.addSubview(btnSkip)
        }
        
        self.window?.rootViewController = self.passcodeViewController
        self.window?.makeKeyAndVisible()
    }
    
    
    //MARK:- TOPASSCODE VIEW CONTROLLER DELEGATE METHODS
    
    func didTapCancel(in passcodeViewController: TOPasscodeViewController) {
        
    }
    
    func passcodeViewController(_ passcodeViewController: TOPasscodeViewController, isCorrectCode code: String) -> Bool {
        
        
        if !self.isLoggedIn {
            if !isConformPasscode {
                OperationQueue.main.addOperation {
                    self.isConformPasscode = true
                    self.strPasscode = code
//                    self.passcodeViewController?.changeTopText(kCONFIRM_PASSCODE)
                    
                }
            } else {
                if code != self.strPasscode {
                    // Toast(text: kCONFIRM_PASSCODE_NOT_SAME_AS_PASSCODE).show()
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                    
                    self.isConformPasscode = false
                    self.strPasscode = ""
//                    self.passcodeViewController?.changeTopText(kSET_PASSCODE)
                } else {
                    let isSaved = (DBManager.sharedManager() as AnyObject).setPasscode(code)
                    
                    if isSaved {
                        
                        //                        let noteCategoryListVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NoteCategoryListVC") as! NoteCategoryListVC
                        //                        let nav = UINavigationController.init(rootViewController: noteCategoryListVC)
                        //                        self.window?.rootViewController = nav
                        //                        self.window?.makeKeyAndVisible()
                        
                        UserDefaults.standard.removeObject(forKey: kIS_SKIPPED)
                        // Toast(text: "Passcode set").show()
                        Coordinator.rootViewContoller(isFirstTime: false)
                    } else {
                        // Toast(text: kPASSCODE_NOTE_SET).show()
                    }
                    return true
                }
            }
        } else {
            let strPasscode = String(describing: (self.arrLoginCredential[0] as! [String : Any])["passcode"]!)
            
            if code == strPasscode {
                //                let noteCategoryListVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NoteCategoryListVC") as! NoteCategoryListVC
                //                let nav = UINavigationController.init(rootViewController: noteCategoryListVC)
                //                self.window?.rootViewController = nav
                //                self.window?.makeKeyAndVisible()
                
                IS_USER_LOGGED_IN = true
                Coordinator.rootViewContoller(isFirstTime: false)
                return true
            } else {
                // Toast(text: kENTER_VALID_PASSCODE).show()
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
        }
        return false
    }
    
    
    func didPerformBiometricValidationRequest(in passcodeViewController: TOPasscodeViewController) {
        
        let context = LAContext()
        var error : NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Indentify", reply: { (isSuccess, error) in
                
                if isSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                        // Toast(text: "Authentication succeed").show()
                        
                        //                        let noteCategoryListVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NoteCategoryListVC") as! NoteCategoryListVC
                        //                        let nav = UINavigationController.init(rootViewController: noteCategoryListVC)
                        //                        self.window?.rootViewController = nav
                        //                        self.window?.makeKeyAndVisible()
                        IS_USER_LOGGED_IN = true
                        Coordinator.rootViewContoller(isFirstTime: false)
                    })
                } else {
                    let err = (error as! LAError).code
                    
                    switch err {
                    case .appCancel:
                        // Toast(text: "Authentication cancel by app").show()
                        break
                        
                    case .authenticationFailed:
                        // Toast(text: "Authentication failed").show()
                        break
                        
                    case .invalidContext:
                        // Toast(text: "Authentication failed due to invaild context").show()
                        break
                        
                    case .passcodeNotSet:
                        // Toast(text: "Passcode not set yet").show()
                        break
                        
                    case .systemCancel:
                        // Toast(text: "Authentication cancel by system").show()
                        break
                        
                    case .touchIDLockout:
                        // Toast(text: "Touch ID lockout").show()
                        break
                        
                    case .touchIDNotAvailable:
                        // Toast(text: "Touch ID not available").show()
                        break
                        
                    case .touchIDNotEnrolled:
                        // Toast(text: "Touch ID not enrolled yet").show()
                        break
                        
                    case .userCancel:
                        // Toast(text: "Authentication cancel by user").show()
                        break
                        
                    case .userFallback:
                        // Toast(text: "Authentication cancel due to user pressed fallback option").show()
                        break
                    case .notInteractive: break
                        // Toast(text: "notInteractive").show()
                    default: break // New SDK error cases remain authentication failures.
                    }
                }
            })
        }
    }
    
    func registerPushNotification() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge, .sound]) { (granted, err) in
            if let error = err {
                print(error.localizedDescription)
            }
            guard granted else{return}
            DispatchQueue.main.sync {
                UIApplication.shared.registerForRemoteNotifications()
            }
            Messaging.messaging().delegate = self
        }
    }
    
    @objc func btnSkipPressed(_ sender : UIButton) {
        UserDefaults.standard.set(true, forKey: kIS_SKIPPED)
        self.passcodeViewController?.dismiss(animated: true, completion: nil)
        
        //        let noteCategoryListVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NoteCategoryListVC") as! NoteCategoryListVC
        //        let nav = UINavigationController.init(rootViewController: noteCategoryListVC)
        //        self.window?.rootViewController = nav
        //        self.window?.makeKeyAndVisible()
        
        Coordinator.rootViewContoller(isFirstTime: false)
    }
    
    func setupIAP() {
        
        if (self.sharedObj?.isReachable)! {
            
            var isProductPurchased = true
            
            SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
                
                print("isProductPurchased \(isProductPurchased) payment \(payment), product \(product)")
                
                return isProductPurchased
            }
            
            SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
                
                for purchase in purchases {
                    switch purchase.transaction.transactionState {
                    case .purchased, .restored:
                        let downloads = purchase.transaction.downloads
                        isProductPurchased = false
                        if !downloads.isEmpty {
                            SwiftyStoreKit.start(downloads)
                        } else if purchase.needsFinishTransaction {
                            // Deliver content from server, then:
                            SwiftyStoreKit.finishTransaction(purchase.transaction)
                        }
                        print("\(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                    case .failed, .purchasing, .deferred:
                        break // do nothing
                    }
                }
            }
            
            SwiftyStoreKit.updatedDownloadsHandler = { downloads in
                
                // contentURL is not nil if downloadState == .finished
                let contentURLs = downloads.compactMap { $0.contentURL }
                if contentURLs.count == downloads.count {
                    print("Saving: \(contentURLs)")
                    SwiftyStoreKit.finishTransaction(downloads[0].transaction)
                }
            }
        }
    }
    
    func observeCommentChanges(for userID: String) {
        guard Auth.auth().currentUser?.uid == userID else { return }
        ApplazActivityInbox.shared.start()
    }

    func observeLikeChanges(for userID: String) {
        guard Auth.auth().currentUser?.uid == userID else { return }
        ApplazActivityInbox.shared.start()
    }

    func sendLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any]? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let info = userInfo {
            content.userInfo = info
        }
        
        // Configure a time interval trigger for immediate delivery (1 second)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // Schedule the request with the system
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing local notification: \(error)")
            }
        }
    }

    func sendCommentLocalNotification(username: String, commentText: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Comment!"
        content.body = "\(username) comment on your note."
        content.sound = UNNotificationSound.default
        
        // Trigger the notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create the notification request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // Add the notification request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error posting local notification: \(error)")
            }
        }
    }
}



// Own the app window through UIKit's scene lifecycle so it survives backgrounding.
class ApplazSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene,
              let app = UIApplication.shared.delegate as? AppDelegate else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        app.window = window
        Coordinator.rootViewContoller(isFirstTime: true)
        self.scene(scene, openURLContexts: connectionOptions.urlContexts)
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        for context in URLContexts {
            var options: [UIApplication.OpenURLOptionsKey: Any] = [.openInPlace: context.options.openInPlace]
            if let source = context.options.sourceApplication { options[.sourceApplication] = source }
            _ = app.application(.shared, open: context.url, options: options)
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationDidEnterBackground(.shared)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationWillResignActive(.shared)
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationWillEnterForeground(.shared)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.applicationDidBecomeActive(.shared)
    }
}
