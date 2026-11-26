//
//  AuthViewController.swift
//
//  Created by Bossly on 9/10/16.
//  Copyright © 2016 Bossly. All rights reserved.
//

import UIKit

import SwiftHEXColors

import Firebase
import FirebaseAuthUI
import FirebaseDatabaseUI
import FirebaseAuth
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI

class WelcomeViewController: UIViewController, FUIAuthDelegate {
    
    @IBOutlet weak var progressView:UIActivityIndicatorView? // view shown while data is loading
    @IBOutlet weak var welcomeView:UIView? // view when data is loaded. like sign-in or intro
    
    private var didOpenAuthenticatedApp = false
    var client:AuthClient?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let analytics = client as? Analytica
        self.welcomeView?.isHidden = true
        self.progressView?.isHidden = false
        self.progressView?.startAnimating()

        let config = RemoteConfig.remoteConfig()
        #if DEBUG
            config.configSettings = RemoteConfigSettings()
        #endif
        
        config.fetch(withExpirationDuration: 100) { (status, error) -> Void in
            
            if status == .success {
                print("Config fetched!")
                config.fetchAndActivate()
                analytics?.trackRemoteConfig(loaded: true)
            } else {
                analytics?.trackRemoteConfig(loaded: false)

                let message = error?.localizedDescription ?? "No error available."
                analytics?.trackError(message: message)
                print("Config not fetched")
                print("Error: \(message)")
            }
            
            DispatchQueue.main.async {
            self.defineTheme(config)
//            self.welcomeView?.isHidden = false
            self.progressView?.isHidden = true
            self.progressView?.stopAnimating()

            // if user authorized, go to main page
            self.openAuthenticatedAppIfNeeded()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        openAuthenticatedAppIfNeeded()
    }

    private func openAuthenticatedAppIfNeeded() {
        guard !didOpenAuthenticatedApp, isViewLoaded, view.window != nil,
              Auth.auth().currentUser != nil else { return }
        didOpenAuthenticatedApp = true
        progressView?.stopAnimating()
        performSegue(withIdentifier: "auth.mute", sender: nil)
    }
    
    // FIRAuthUIDelegate
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if let errorHandler = error as NSError? {
            self.showError(errorHandler.localizedDescription)
            // print user-info. find more here: https://firebase.google.com/docs/auth/ios/errors
            print(errorHandler.userInfo)
        } else {
            if let currentUser = user {
                
                // update displayname and photo
                let name = currentUser.displayName ?? kDefaultUsername
                let photo = currentUser.photoURL?.absoluteString ?? kDefaultProfilePhoto
                
                client?.saveUser(userId: currentUser.uid,
                                             name: name,
                                             photo: photo,
                                             override: false)
                Messaging.messaging().subscribe(toTopic: "\(kTopicFeed)\(currentUser.uid)")
            }

            self.performSegue(withIdentifier: "auth", sender: nil)
        }
    }
    
    // Helpers
    
    func showError(_ error:String) {
        print("Error: \(error)")
        
        let alert = UIAlertController(title: kAlertErrorTitle, message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: kAlertErrorDefaultButton, style: .default) { (action) in })
        self.present(alert, animated: true) {}
    }
    
    func defineTheme(_ config:RemoteConfig) {
        UINavigationBar.appearance().barTintColor = .primary
        UINavigationBar.appearance().tintColor = .secondary
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [NSAttributedString.Key.foregroundColor: UIColor.secondary], for: UIControl.State.normal)
        
        UITabBar.appearance().barTintColor = .primary
        UITabBar.appearance().tintColor = .secondary
        UIButton.appearance().tintColor = .secondary
    }

    // Actions
    @IBAction func termsClicked() {
        if let url = URL(string:kEulaUrl) {
            UIApplication.shared.openURL(url)
        }
    }

    @IBAction func buttonPressed(_ sender: AnyObject) {
        let authUI = FUIAuth.defaultAuthUI()
        authUI?.delegate = self

        /* 
         * Uncommend this lines to add Google and Facebook authorization. But first 
         * enabled it in Firebase Console. More information you can find here:
         * https://firebase.google.com/docs/auth/ios/google-signin
         * https://firebase.google.com/docs/auth/ios/facebook-login
         */
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth(),
            FUIFacebookAuth(),
//            FUITwitterAuth()
            ]
        authUI?.providers = providers
        // authUI?.isSignInWithEmailHidden = true

        /*
         kEulaUrl needs to be set in Config.swift file. required for publishing
         */
        authUI?.tosurl = URL(string:kEulaUrl)
        
        if (Auth.auth().currentUser) != nil {
            self.performSegue(withIdentifier: "auth.mute", sender: nil)
        } else {
            let authViewController = authUI!.authViewController()
            self.present(authViewController, animated: true) { }
        }
    }
    
}
