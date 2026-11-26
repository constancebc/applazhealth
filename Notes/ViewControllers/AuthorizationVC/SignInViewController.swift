//
//  SignInViewController.swift
//  Notes
//
//  Created by Andrei Yarash on 12/17/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit
import AuthenticationServices

class SignInViewController: UIViewController {
    
    let iapObj = IAPHelper()
    var sharedObj: Shared?
    
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    private var isSigningIn = false
    private var firebaseAuth:FirebaseAuthoriztion = FirebaseAuthoriztion()
    
    
    // Test Database
    private var database = DatabaseService()
    
    @IBAction func signIn(_ sender: Any) {
        
        signInWithEmail()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // UIApplication.shared.statusBarStyle = .default
        
        sharedObj = Shared.sharedInstance
        
        loginButton.isEnabled = false
        emailTextField.textContentType = .username
        passwordTextField.textContentType = .password
        emailTextField.addTarget(self, action: #selector(updateLoginAvailability), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(updateLoginAvailability), for: .editingChanged)
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        self.firebaseAuth.mainVC = self
        termsLabel.isUserInteractionEnabled = true
        
        // Add a tap gesture recognizer to the label
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(termsTapped(_:)))
        termsLabel.addGestureRecognizer(tapGesture)
        ApplazAuthLayout.install(in: view, fields: [emailTextField, passwordTextField], primary: loginButton, terms: termsLabel, signingUp: false)
        /*
         // verify in app purchase
         if (self.sharedObj?.isReachable)! {
         
         //iapObj.autoRenewableVerifyPurchase(isShowActivity: true)
         //iapObj.autoRenewableGetInfo()
         
         if sharedObj!.isProductPurchased == false {
         
         let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
         let vc = mainStoryboard.instantiateViewController(withIdentifier: "PurchaseIntroVC") as! PurchaseIntroVC
         self.present(vc, animated: true, completion: nil)
         
         return
         }
         }
         */
    }
    
    @objc private func updateLoginAvailability() {
        loginButton.isEnabled = !isSigningIn && !(emailTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !(passwordTextField.text ?? "").isEmpty
    }

    private func signInWithEmail() {
        guard !isSigningIn else { return }
        view.endEditing(true)
        isSigningIn = true
        loginButton.isEnabled = false
        loginButton.configuration?.showsActivityIndicator = true
        firebaseAuth.signInFirebase(with: emailTextField.text, password: passwordTextField.text) { [weak self] in
            guard let self else { return }
            self.isSigningIn = false
            self.loginButton.configuration?.showsActivityIndicator = false
            self.updateLoginAvailability()
        }
    }
    @objc func termsTapped(_ sender: UITapGestureRecognizer) {
        let termsRange = (termsLabel.text! as NSString).range(of: "Terms")
        
        // Get the range of tapped text
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: termsLabel.attributedText!)
        
        let tapLocation = sender.location(in: termsLabel)
        let locationOfTouchInLabel = tapLocation
        let labelSize = termsLabel.bounds.size
        textContainer.size = labelSize
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = termsLabel.numberOfLines
        let textStorageRange = NSRange(location: 0, length: textStorage.length)
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInLabel, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // Check if the tap was on the "Terms" text range
        if NSLocationInRange(indexOfCharacter, termsRange) {
            // Open the URL or perform any action you want for the "Terms" link
            if let url = URL(string: "http://whirlpost.co/1051-2/") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}


extension SignInViewController: UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.emailTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.emailTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (passwordTextField.isFirstResponder) {
            guard let text = passwordTextField.text else{return true}
            let newLenght = text.count + string.count - range.length
            return newLenght <= 1000
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateLoginAvailability()
    }
    
}
