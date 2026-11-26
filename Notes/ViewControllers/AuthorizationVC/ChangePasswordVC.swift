//
//  ChangePasswordVC.swift
//  Whirlpost
//
//  Created by Andrei Yarash on 12/23/18.
//  Copyright © 2018 Sevenstar Infotech. All rights reserved.
//

import UIKit

class ChangePasswordVC: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var resetPass: UIButton!
    
    @IBOutlet weak var topConstraintLayout: NSLayoutConstraint!
    
    private var firebaseAuth = FirebaseAuthoriztion()
    
    @IBAction func updatePassword(_ sender: Any) {
        firebaseAuth.updateUserPassword(email: emailTextField.text)
    }
    
    @IBAction func runSignInScene(_ sender: Any) {
       navigationController?.popViewController(animated: true)
        
    }
    
    override func viewWillLayoutSubviews() {
        topConstraintLayout.constant = IS_IPHONE_4_OR_5 ? 50 : 147
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        resetPass.isEnabled = false
        emailTextField.delegate = self
        firebaseAuth.mainVC = self
    }

}

extension ChangePasswordVC: UITextFieldDelegate {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.emailTextField.resignFirstResponder()
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.emailTextField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
       
            guard let text = self.emailTextField.text else{return true}
            let newLenght = text.count + string.count - range.length
            return newLenght <= 30
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.text?.count != 0) {
            resetPass.isEnabled = true
        } else {
            resetPass.isEnabled = false
        }
    }
}
