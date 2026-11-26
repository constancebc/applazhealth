//
//  WelcomPopUpVC.swift
//  Whirlpost
//
//  Created by Nodirbek Maksumov on 3/28/19.
//  Copyright © 2019 Sevenstar Infotech. All rights reserved.
//

import UIKit

class WelcomPopUpVC: UIViewController {

    @IBOutlet weak var popUpView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        popUpView.addCornerRadius(radius: 15)
    }
    

    @IBAction func okBtnPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
