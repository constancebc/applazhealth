//
//  SignUpViewController.swift
//  Notes
//
//  Created by Andrei Yarash on 12/17/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit

class SignUpViewController: UIViewController {

    @IBOutlet weak var termsLabel: UILabel!
    @IBOutlet weak var userTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var topLayoutConstraint: NSLayoutConstraint!
    
    private var firebaseAuth:FirebaseAuthoriztion = FirebaseAuthoriztion()
    private var userTextFieldEditingEndedByButton = false
    // TESTING DATABASE
    private var database = DatabaseService()
    private var shouldEnableButton = false
    
    @IBAction func signUpWithEmail(_ sender: Any) {
        let userName = userTextField.text ?? ""
        if userName.isEmpty {
            self.normal_AlertMessage(message: "Please Enter User Name")
            return
        }
        self.createUser()
    }

    @IBAction func goToSignInScene(_ sender: Any) {
        
        for viewObj in self.navigationController!.viewControllers {
            
            if viewObj .isKind(of: SignInViewController.self) {
                
                navigationController?.popToViewController(viewObj, animated: true)
                return
            }
        }
        
        let mainStoryboard = UIStoryboard(name: "Authorization", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: SignInKeysItems.StoryboardID.signInViewContoller) as! SignInViewController
        navigationController?.pushViewController(vc, animated: true)

    }
    private func createUser() {
        Indicator.shared.showProgressView(self.view)
        firebaseAuth.signUpFirebase(emailAddress: emailTextField.text, password: passwordTextField.text) { dataResult in
            Indicator.shared.hideProgressView()
            switch dataResult {
            case .success:
                
                /// Create the username in dataBase.
                self.database.writeUserNameWithEmail(username: self.userTextField.text!, email: self.emailTextField.text!)
                
                if let userName = self.userTextField.text {
                    UserDefaults.standard.set(userName, forKey: "User_Name")
                    var user: SocialUserModel?
                    user?.name = userName
                    user?.saveData()
                }
                

                
                self.firebaseAuth.signInFirebase(with: self.emailTextField.text, password: self.passwordTextField.text)
                
//                let mainStoryboard = UIStoryboard(name: "Authorization", bundle: nil)
//                let vc = mainStoryboard.instantiateViewController(withIdentifier: SignInKeysItems.StoryboardID.signInViewContoller) as! SignInViewController
//
//                self.navigationController?.pushViewController(vc, animated: true)
                
            case .failure(let error):
                debugPrint("This is getting error", error.localizedDescription)
                self.normal_AlertMessage(title: "Sign up Error",
                                         message: error.localizedDescription,
                                         okButtonTitle: "Continue")
            }
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
    
    @IBAction func runGuestMode(_ sender: Any) {
        
        UserDefaults.standard.set(true, forKey: Guest_Key)
        
            let vc = WellnessOnboarding.home()
                self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        registerButton.isEnabled = false
        userTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        firebaseAuth.mainVC = self
        userTextField.tag = 1
        
        termsLabel.isUserInteractionEnabled = true
        
        // Add a tap gesture recognizer to the label
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(termsTapped(_:)))
        termsLabel.addGestureRecognizer(tapGesture)
        ApplazAuthLayout.install(in: view, fields: [userTextField, emailTextField, passwordTextField], primary: registerButton, terms: termsLabel, signingUp: true)
    }
}

extension SignUpViewController: UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
       // userTextField.resignFirstResponder()
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userTextField{
            userTextField.resignFirstResponder()
        }
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (passwordTextField.isFirstResponder) {
            guard let text = textField.text else{return true}
            let length = text.count + string.count - range.length
            return length <= 12
        } else if (userTextField.isFirstResponder) {
            guard let text = textField.text else{return true}
            let length = text.count + string.count - range.length
            let texts = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890_")
            
            return length <= 30 && (userTextField.text! + string).rangeOfCharacter(from: texts.inverted) == nil
        }
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("in end editing before ==\(userTextFieldEditingEndedByButton)")
        if (textField == userTextField){
            print("in end editing ==\(userTextFieldEditingEndedByButton)")
            let userName = userTextField.text ?? ""
            if !userName.isEmpty {
                self.database.checkIfUserNameExistOrNot(userName: userName) { [self] isExist in
                    self.database.removeFirebaseObserver()
                    if isExist {
                        self.normal_AlertMessage(message: "The entered username is already exists, Please enter new username.")
                        self.registerButton.isEnabled = false
                        shouldEnableButton = false
                    } else {
                        self.registerButton.isEnabled = true
                        shouldEnableButton = true
                    }
                }
            }else{
                self.registerButton.isEnabled = false
                shouldEnableButton = false
            }
        }
        if (emailTextField.text?.count != 0 && passwordTextField.text?.count != 0 && shouldEnableButton) {
            self.registerButton.isEnabled = true
        } else {
            self.registerButton.isEnabled = false
        }
    }
}
