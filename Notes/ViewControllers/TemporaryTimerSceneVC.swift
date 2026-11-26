//
//  TemporaryTimerSceneVC.swift
//  Whirlpost
//
//  Created by Andrei Yarash on 2/19/19.
//  Copyright © 2019 Sevenstar Infotech. All rights reserved.
//

import UIKit

class TemporaryTimerSceneVC: UIViewController {

    
    @objc private func showPopUpScreen() {
//
//        let settingsVC = self.storyboard?.instantiateViewController(withIdentifier: "PopUpTimerSceneVC") as! PopUpTimerSceneVC
//        settingsVC.modalPresentationStyle = .overCurrentContext
//        self.navigationController?.modalPresentationStyle = .overCurrentContext
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.window?.rootViewController?.present(settingsVC, animated: true, completion: nil)
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        let simpleVC = storyboard.instantiateViewController(withIdentifier: "NoteCategoryListVC") as! NoteCategoryListVC
        self.navigationController?.pushViewController(simpleVC, animated: true)
        
    }
    
    @IBAction func backToSignUp(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func runTimer(_ sender: Any) {
        
        let alertVC = UIAlertController(title: "Timer is running", message: nil, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            let _ = Timer.scheduledTimer(timeInterval: 1, target: self!, selector: #selector(self?.showPopUpScreen), userInfo: nil, repeats: false)
            
        }
        alertVC.addAction(alertAction)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    navigationController?.interactivePopGestureRecognizer?.isEnabled = false
       
    }
    

}
